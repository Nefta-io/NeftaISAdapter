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
    }
    
    public class AdRequest: NSObject, LPMRewardedAdDelegate {
        private let _controller: Rewarded
        
        public let _adUnitId: String
        public var _rewarded: LPMRewardedAd?
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        public var _consecutiveAdFails: Int = 0
        
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
            _consecutiveAdFails += 1
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        func didLoadAd(with adInfo: LPMAdInfo) {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
            
            _controller.Log("Loaded \(adInfo) at: \(adInfo.revenue.doubleValue)")
            
            _insight = nil
            _consecutiveAdFails = 0
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
        }
        
        func didDisplayAd(with adInfo: LPMAdInfo) {
            _controller.Log("didDisplayAd \(adInfo)")
        }
        
        func didCloseAd(with adInfo: LPMAdInfo) {
            _controller.Log("didCloseAd \(String(describing: adInfo))")
            
            _controller.RetryLoading()
        }
        
        func retryLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self._state = State.Idle
                self._controller.RetryLoading()
            }
        }
    }
    
    private var _adRequestA: AdRequest!
    private var _adRequestB: AdRequest!
    private var _isFirstResponseReceived = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    private var _viewController: UIViewController!
    
    private func StartLoading() {
        Load(request: _adRequestA, otherState: _adRequestB._state)
        Load(request: _adRequestB, otherState: _adRequestA._state)
    }
    
    private func Load(request: AdRequest, otherState: State) {
        if request._state == State.Idle {
            if otherState != State.LoadingWithInsights {
                GetInsightsAndLoad(adRequest: request)
            } else if (_isFirstResponseReceived) {
                LoadDefault(adRequest: request)
            }
        }
    }
    
    private func GetInsightsAndLoad(adRequest: AdRequest) {
        adRequest._state = State.LoadingWithInsights
        
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, previousInsight: adRequest._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._rewarded {
                adRequest._insight = insight
                let config = LPMRewardedAdConfigBuilder()
                    .set(bidFloor: insight._floorPrice as NSNumber)
                    .build()
                adRequest._rewarded = LPMRewardedAd(adUnitId: adRequest._adUnitId, config: config)
                adRequest._rewarded!.setDelegate(adRequest)
                adRequest._rewarded!.loadAd()
                
                ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!, adUnitId: adRequest._adUnitId, insight: insight)
            } else {
                adRequest.OnLoadFail()
            }
        }, timeout: TimeoutInSeconds)
    }
    
    private func LoadDefault(adRequest: AdRequest) {
        adRequest._state = State.Loading
        
        Log("Loading \(adRequest._adUnitId) as Default")
        
        adRequest._rewarded = LPMRewardedAd(adUnitId: AdUnitB)
        adRequest._rewarded!.setDelegate(adRequest)
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!, adUnitId: adRequest._adUnitId, insight: nil)
        
        adRequest._rewarded!.loadAd()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        _viewController = findViewController()
        
        _adRequestA = AdRequest(controller: self, adUnitId: AdUnitA)
        _adRequestB = AdRequest(controller: self, adUnitId: AdUnitB)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            StartLoading()
        }
    }
    
    @objc func OnShowClick() {
        var isShown = false
        if _adRequestA._state == State.Ready {
            if _adRequestB._state == State.Ready && _adRequestB._revenue > _adRequestA._revenue {
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
    
    private func TryShow(adRequest: AdRequest) -> Bool {
        adRequest._state = State.Idle
        adRequest._revenue = -1

        if adRequest._rewarded!.isAdReady() {
            adRequest._rewarded!.showAd(viewController: _viewController, placementName: nil)
            return true
        }
        RetryLoading()
        return false
    }
    
    private func RetryLoading() {
        if self._loadSwitch.isOn {
            self.StartLoading()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseReceived = true
        RetryLoading()
    }
    
    private func UpdateShowButton() {
        _showButton.isEnabled = _adRequestA._state == State.Ready || _adRequestB._state == State.Ready
    }
    
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginIS Rewarded: \(log, privacy: .public)")
    }
}
