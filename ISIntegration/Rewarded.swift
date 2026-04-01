//
//  Rewarded.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

import Foundation
import IronSource

class Rewarded : UIView {
    private let AdUnitA = "p3dh8r1mm3ua8fvv"
    private let AdUnitB = "doucurq8qtlnuz7p"
    private let TimeoutInSeconds = 5
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
        case Shown
    }
    
    public class Track: NSObject, LPMRewardedAdDelegate {
        private let _controller: Rewarded
        
        public let _adUnitId: String
        public var _rewarded: LPMRewardedAd?
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: Rewarded, adUnitId: String) {
            _controller = controller
            _adUnitId = adUnitId
        }
        
        func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
            let lpError = error as NSError
            ISNeftaCustomAdapter.onExternalMediationRequestFail(lpError)
            
            _controller.Log("Load failed \(adUnitId): \(error.localizedDescription)")
            
            _rewarded = nil
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func didLoadAd(with adInfo: LPMAdInfo) {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
            
            _controller.Log("Loaded \(adInfo) at: \(adInfo.revenue.doubleValue)")
            
            _insight = nil
            _revenue = adInfo.revenue.doubleValue
            _state = State.Ready
            
            _controller.OnTrackLoad(true)
        }
        
        func didClickAd(with adInfo: LPMAdInfo) {
            _controller.Log("didClickAd \(String(describing: adInfo))")
            
            ISNeftaCustomAdapter.onExternalMediationClick(adInfo)
        }
        
        func didRewardAd(with adInfo: LPMAdInfo, reward: LPMReward) {
            _controller.Log("didRewardAd \(adInfo)")
        }
        
        func didFailToShowWithError(_ error: (any Error)!, andAdInfo adInfo: ISAdInfo!) {
            _controller.Log("didFailToShowWithError \(String(describing: error.self))")
            
            _state = .Idle
            _controller.RetryLoadTracks()
        }
        
        func didDisplayAd(with adInfo: LPMAdInfo) {
            _controller.Log("didDisplayAd \(adInfo)")
        }
        
        func didCloseAd(with adInfo: LPMAdInfo) {
            _controller.Log("didCloseAd \(String(describing: adInfo))")
            
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
    
    private var _adRequestA: Track!
    private var _adRequestB: Track!
    private var _isFirstResponseReceived = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    private var _viewController: UIViewController!
    
    private func LoadTracks() {
        LoadTrack(track: _adRequestA, otherState: _adRequestB._state)
        LoadTrack(track: _adRequestB, otherState: _adRequestA._state)
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
        
        NeftaPlugin._instance!.GetInsights(Insights.Rewarded, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._rewarded {
                track._insight = insight
                let config = LPMRewardedAdConfigBuilder()
                    .set(bidFloor: insight._floorPrice as NSNumber)
                    .build()
                track._rewarded = LPMRewardedAd(adUnitId: track._adUnitId, config: config)
                track._rewarded!.setDelegate(track)
                track._rewarded!.loadAd()
                
                ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: track._rewarded!, adUnitId: track._adUnitId, insight: insight)
            } else {
                track.OnLoadFail()
            }
        })
    }
    
    private func LoadDefault(track: Track) {
        track._state = .Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._rewarded = LPMRewardedAd(adUnitId: AdUnitB)
        track._rewarded!.setDelegate(track)
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: track._rewarded!, adUnitId: track._adUnitId, insight: nil)
        
        track._rewarded!.loadAd()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        _viewController = findViewController()
        
        _adRequestA = Track(controller: self, adUnitId: AdUnitA)
        _adRequestB = Track(controller: self, adUnitId: AdUnitB)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        RetryLoadTracks()
    }
    
    @objc func OnShowClick() {
        var isShown = false
        if _adRequestA._state == .Ready {
            if _adRequestB._state == .Ready && _adRequestB._revenue > _adRequestA._revenue {
                isShown = TryShow(adRequest: _adRequestB)
            }
            if !isShown {
                isShown = TryShow(adRequest: _adRequestA)
            }
        }
        if !isShown && _adRequestB._state == State.Ready {
            isShown = TryShow(adRequest: _adRequestB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(adRequest: Track) -> Bool {
        adRequest._revenue = -1
        if adRequest._rewarded!.isAdReady() {
            adRequest._state = .Shown
            adRequest._rewarded!.showAd(viewController: _viewController, placementName: nil)
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
        _showButton.isEnabled = _adRequestA._state == State.Ready || _adRequestB._state == State.Ready
    }
    
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginIS Rewarded: \(log, privacy: .public)")
    }
}
