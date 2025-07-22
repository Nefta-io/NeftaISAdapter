//
//  Rewarded.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

import Foundation
import IronSource

class Rewarded : NSObject, LPMRewardedAdDelegate {

    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    private var _isLoading = false
    
    private var _rewarded: LPMRewardedAd!
    private var _usedInsight: AdInsight?
    private var _requestedFloorPrice: Double = 0
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, callback: Load, timeout: 5)
    }
    
    private func Load(insights: Insights) {
        _requestedFloorPrice = 0
        _usedInsight = insights._rewarded
        if let usedInsight = _usedInsight {
            _requestedFloorPrice = usedInsight._floorPrice
        }
        
        SetInfo("Loading Rewarded with floor: \(_requestedFloorPrice)")
        
        let config = LPMRewardedAdConfigBuilder()
            .set(bidFloor: _requestedFloorPrice as NSNumber)
            .build()
        
        _rewarded = LPMRewardedAd(adUnitId: "doucurq8qtlnuz7p", config: config)
        _rewarded.setDelegate(self)
        _rewarded.loadAd()
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        ISNeftaCustomAdapter.onExternalMediationRequestFail(.rewarded, usedInsight: _usedInsight, requestedFloorPrice: _requestedFloorPrice, adUnitId: adUnitId, error: error as NSError)
        
        SetInfo("didFailToLoadAd \(adUnitId): \(error.localizedDescription)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self._isLoading {
                self.GetInsightsAndLoad()
            }
        }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(.rewarded, usedInsight: _usedInsight, requestedFloorPrice: _requestedFloorPrice, adInfo: adInfo)
        
        SetInfo("didLoadAd \(adInfo)")
        
        SetLoadingButton(isLoading: false)
        _loadButton.isEnabled = false
        _showButton.isEnabled = true
    }
    
    init(loadButton: UIButton, showButton: UIButton, status: UILabel, viewController: ViewController) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(OnLoadClick), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _loadButton.isEnabled = false
        _showButton.isEnabled = false
    }
    
    func Create() {
        _loadButton.isEnabled = true
    }
    
    @objc func OnLoadClick() {
        if _isLoading {
            SetLoadingButton(isLoading: false)
        } else {
            SetInfo("GetInsightsAndLoad...")
            GetInsightsAndLoad()
            SetLoadingButton(isLoading: true)
        }
    }
    
    @objc func OnShowClick() {
        _rewarded.showAd(viewController: _viewController, placementName: nil)
        
        _loadButton.isEnabled = true
        _showButton.isEnabled = false
    }
    
    func didRewardAd(with adInfo: LPMAdInfo, reward: LPMReward) {
        SetInfo("didRewardAd \(adInfo)")
    }
    
    func didFailToShowWithError(_ error: (any Error)!, andAdInfo adInfo: ISAdInfo!) {
        SetInfo("didFailToShowWithError \(String(describing: error.self))")
    }
    
    func didDisplayAd(with adInfo: LPMAdInfo) {
        SetInfo("didDisplayAd \(adInfo)")
    }
    
    func didClickAd(with adInfo: LPMAdInfo) {
        SetInfo("didClickAd \(String(describing: adInfo))")
    }
    
    func didCloseAd(with adInfo: LPMAdInfo) {
        SetInfo("didCloseAd \(String(describing: adInfo))")
        _loadButton.isEnabled = true
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
    
    private func SetLoadingButton(isLoading: Bool) {
        if isLoading {
            _loadButton.setTitle("Cancel", for: .normal)
            _isLoading = true
        } else {
            _loadButton.setTitle("Load Interstitial", for: .normal)
            _isLoading = false
        }
    }
}
