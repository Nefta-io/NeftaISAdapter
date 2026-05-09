//
//  InterstitialOptimized.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

import Foundation
import IronSource

class InterstitialOptimized : Interstitial {
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track: NSObject, LPMInterstitialAdDelegate {
        private let _controller: InterstitialOptimized
        
        public let _adUnitId: String
        public var _interstitial: LPMInterstitialAd?
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: InterstitialOptimized, adUnitId: String) {
            _adUnitId = adUnitId
            _controller = controller
        }
        
        func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
            let lpError = error as NSError
            ISNeftaCustomAdapter.onExternalMediationRequestFail(lpError)
            
            _controller.Log("Load failed \(adUnitId): \(error.localizedDescription)")
            
            _interstitial = nil
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func didLoadAd(with adInfo: LPMAdInfo) {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
            
            _insight = nil
            _revenue = adInfo.revenue.doubleValue
            _state = .Ready
            
            _controller.OnTrackLoad(true)
        }
        
        func didClickAd(with adInfo: LPMAdInfo) {
            _controller.Log("didClick \(adInfo.adNetwork)")
            
            ISNeftaCustomAdapter.onExternalMediationClick(adInfo)
        }
        
        func didChangeAdInfo(_ adInfo: LPMAdInfo) {
            _controller.Log("didChangeAdInfo \(adInfo.adNetwork)")
        }
        
        func didFailToDisplayAd(withAdUnitId adUnitId: String, error: any Error) {
            _controller.Log("didFailToDisplayAd \(adUnitId): \(error.localizedDescription)")
            
            _state = .Idle
            _controller.RetryLoadTracks()
        }
        
        func didDisplayAd(with adInfo: LPMAdInfo) {
            _controller.Log("didOpen \(adInfo.adNetwork)")
        }
        
        func didCloseAd(with adInfo: LPMAdInfo) {
            _controller.Log("didCloseAd \(adInfo.adNetwork)")
            
            _state = .Idle
            _controller.RetryLoadTracks()
        }
        
        func retryLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + ISNeftaCustomAdapter.GetRetryDelayInSeconds(insight: _insight)) {
                self._state = .Idle
                self._controller.RetryLoadTracks()
            }
        }
    }
    
    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false
    
    private var _ui: InterstitialUi!
    
    func Init(ui: InterstitialUi) {
        _ui = ui
        
        _trackA = Track(controller: self, adUnitId: InterstitialUi.AdUnitA)
        _trackB = Track(controller: self, adUnitId: InterstitialUi.AdUnitB)
    }
    
    public func Load() {
        LoadTrack(track: _trackA, otherState: _trackB._state)
        LoadTrack(track: _trackB, otherState: _trackA._state)
    }
    
    private func LoadTrack(track: Track, otherState: State) {
        if track._state == .Idle {
            if otherState == .LoadingWithInsights || otherState == .Shown {
                if (_isFirstResponseReceived) {
                    LoadDefault(track: track)
                }
            } else {
                GetInsightsAndLoad(track: track)
            }
        }
    }
    
    private func GetInsightsAndLoad(track: Track) {
        track._state = .LoadingWithInsights
        
        NeftaPlugin._instance!.GetInsights(Insights.Interstitial, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._interstitial {
                track._insight = insight
                if insight._floorPrice >= 0 {
                    let config = LPMInterstitialAdConfigBuilder()
                        .set(bidFloor: insight._floorPrice as NSNumber)
                        .build()
                    track._interstitial = LPMInterstitialAd(adUnitId: track._adUnitId, config: config)
                } else {
                    track._interstitial = LPMInterstitialAd(adUnitId: track._adUnitId)
                }
                track._interstitial!.setDelegate(track)
                
                ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: track._interstitial!, adUnitId: track._adUnitId, insight: insight)
                
                self.Log("Loading \(track._adUnitId) as Optimized with floor: \(insight._floorPrice)")
                track._interstitial!.loadAd()
            } else {
                track.OnLoadFail()
            }
        })
    }
    
    private func LoadDefault(track: Track) {
        track._state = .Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._interstitial = LPMInterstitialAd(adUnitId: track._adUnitId)
        track._interstitial!.setDelegate(track)
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: track._interstitial!, adUnitId: track._adUnitId, insight: nil)
        
        track._interstitial!.loadAd()
    }
    
    public func Show() {
        var isShown = false
        if _trackA._state == .Ready {
            if _trackB._state == .Ready && _trackB._revenue > _trackA._revenue {
                isShown = TryShow(track: _trackB)
            }
            if !isShown {
                isShown = TryShow(track: _trackA)
            }
        }
        if !isShown && _trackB._state == .Ready {
            isShown = TryShow(track: _trackB)
        }
        
        UpdateAvailability()
    }
    
    private func TryShow(track: Track) -> Bool {
        track._revenue = -1
        if track._interstitial!.isAdReady() {
            track._state = .Shown
            track._interstitial!.showAd(viewController: _ui.ViewController, placementName: nil)
            return true
        }
        track._state = .Idle
        RetryLoadTracks()
        return false
    }
    
    private func RetryLoadTracks() {
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateAvailability()
        }
        
        _isFirstResponseReceived = true
        RetryLoadTracks()
    }
    
    private func UpdateAvailability() {
        _ui.SetAvailable(available: _trackA._state == .Ready || _trackB._state == .Ready)
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
