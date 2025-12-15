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
    }
    
    public class AdRequest: NSObject, LPMInterstitialAdDelegate {
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
            _state = State.Ready
            
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
        }
        
        func didDisplayAd(with adInfo: LPMAdInfo) {
            _controller.Log("didOpen \(adInfo.adNetwork)")
        }
        
        func didCloseAd(with adInfo: LPMAdInfo) {
            _controller.Log("didCloseAd \(adInfo.adNetwork)")
            
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
        
        NeftaPlugin._instance.GetInsights(Insights.Interstitial, previousInsight: adRequest._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._interstitial {
                adRequest._insight = insight
                let config = LPMInterstitialAdConfigBuilder()
                    .set(bidFloor: insight._floorPrice as NSNumber)
                    .build()
                adRequest._interstitial = LPMInterstitialAd(adUnitId: adRequest._adUnitId, config: config)
                adRequest._interstitial!.setDelegate(adRequest)
                
                ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: adRequest._interstitial!, adUnitId: adRequest._adUnitId, insight: insight)
                
                self.Log("Loading \(adRequest._adUnitId) as Optimized with floor: \(insight._floorPrice)")
                adRequest._interstitial!.loadAd()
            } else {
                adRequest.OnLoadFail()
            }
        }, timeout: TimeoutInSeconds)
    }
    
    private func LoadDefault(adRequest: AdRequest) {
        adRequest._state = State.Loading
        
        Log("Loading \(adRequest._adUnitId) as Default")
        
        adRequest._interstitial = LPMInterstitialAd(adUnitId: AdUnitB)
        adRequest._interstitial!.setDelegate(adRequest)
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: adRequest._interstitial!, adUnitId: adRequest._adUnitId, insight: nil)
        
        adRequest._interstitial!.loadAd()
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

        if adRequest._interstitial!.isAdReady() {
            adRequest._interstitial!.showAd(viewController: _viewController, placementName: nil)
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
        ViewController._log.info("NeftaPluginIS Interstitial: \(log, privacy: .public)")
    }
}
