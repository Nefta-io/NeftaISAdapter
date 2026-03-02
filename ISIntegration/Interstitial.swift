//
//  Interstitial.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

import Foundation
import IronSource

class Interstitial : UIView {
    
    private let AdUnitA = "g7xalw41x4i1bj5t"
    private let AdUnitB = "q0z1act0tdckh4mg"
    private let TimeoutInSeconds = 5
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track: NSObject, LPMInterstitialAdDelegate {
        private let _controller: Interstitial
        
        public let _adUnitId: String
        public var _interstitial: LPMInterstitialAd?
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        public var _consecutiveAdFails: Int = 0
        
        public init(controller: Interstitial, adUnitId: String) {
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
            _consecutiveAdFails += 1
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func didLoadAd(with adInfo: LPMAdInfo) {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
            
            _insight = nil
            _consecutiveAdFails = 0
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self._state = .Idle
                self._controller.RetryLoadTracks()
            }
        }
    }
    
    private var _trackA: Track!
    private var _trackB: Track!
    private var _isFirstResponseReceived = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    private var _viewController: UIViewController!
    
    private func LoadTracks() {
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
                let config = LPMInterstitialAdConfigBuilder()
                    .set(bidFloor: insight._floorPrice as NSNumber)
                    .build()
                track._interstitial = LPMInterstitialAd(adUnitId: track._adUnitId, config: config)
                track._interstitial!.setDelegate(track)
                
                ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: track._interstitial!, adUnitId: track._adUnitId, insight: insight)
                
                self.Log("Loading \(track._adUnitId) as Optimized with floor: \(insight._floorPrice)")
                track._interstitial!.loadAd()
            } else {
                track.OnLoadFail()
            }
        }, timeout: TimeoutInSeconds)
    }
    
    private func LoadDefault(track: Track) {
        track._state = .Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._interstitial = LPMInterstitialAd(adUnitId: AdUnitB)
        track._interstitial!.setDelegate(track)
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: track._interstitial!, adUnitId: track._adUnitId, insight: nil)
        
        track._interstitial!.loadAd()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        _viewController = findViewController()
        
        _trackA = Track(controller: self, adUnitId: AdUnitA)
        _trackB = Track(controller: self, adUnitId: AdUnitB)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        RetryLoadTracks()
    }
    
    @objc func OnShowClick() {
        var isShown = false
        if _trackA._state == .Ready {
            if _trackB._state == .Ready && _trackB._revenue > _trackA._revenue {
                isShown = TryShow(adRequest: _trackB)
            }
            if !isShown {
                isShown = TryShow(adRequest: _trackA)
            }
        }
        if !isShown && _trackB._state == .Ready {
            isShown = TryShow(adRequest: _trackB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(adRequest: Track) -> Bool {
        adRequest._revenue = -1
        if adRequest._interstitial!.isAdReady() {
            adRequest._state = .Shown
            adRequest._interstitial!.showAd(viewController: _viewController, placementName: nil)
            return true
        }
        adRequest._state = .Idle
        RetryLoadTracks()
        return false
    }
    
    private func RetryLoadTracks() {
        if self._loadSwitch.isOn {
            self.LoadTracks()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseReceived = true
        RetryLoadTracks()
    }
    
    private func UpdateShowButton() {
        _showButton.isEnabled = _trackA._state == .Ready || _trackB._state == .Ready
    }
    
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginIS Interstitial: \(log, privacy: .public)")
    }
}
