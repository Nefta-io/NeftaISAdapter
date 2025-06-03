//
//  Interstitial.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

import Foundation
import IronSource

class Interstitial : NSObject, LPMInterstitialAdDelegate {
    
    private let FloorPriceInsightName = "calculated_user_floor_price_interstitial"
    
    private var _requestedBidFloor: Double = 0.0
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested: Bool = false
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private var _viewController: UIViewController
    
    private var _interstitialAd: LPMInterstitialAd!
    
    private func GetInsightsAndLoad() {
        _isLoadRequested = true
        
        NeftaPlugin._instance.GetBehaviourInsight([FloorPriceInsightName], callback: OnBehaviourInsight)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self._isLoadRequested {
                self._calculatedBidFloor = 0
                self.Load()
            }
        }
    }
    
    func OnBehaviourInsight(insights: [String: Insight]) {
        _calculatedBidFloor = 0
        if let bidFloorInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = bidFloorInsight._float
        }
        
        print("OnBehaviourInsight for Interstitial calculated bid floor: \(_calculatedBidFloor)")
        
        if _isLoadRequested {
            Load()
        }
    }
    
    func Load() {
        _isLoadRequested = false
        
        if _calculatedBidFloor == 0 {
            _requestedBidFloor = 0
            IronSource.setWaterfallConfiguration(ISWaterfallConfiguration.clear(), for: ISAdUnit.is_AD_UNIT_INTERSTITIAL())
        } else {
            _requestedBidFloor = _calculatedBidFloor
            let configuration = ISWaterfallConfiguration.builder()
                .setFloor(NSNumber(value: _requestedBidFloor))
                .build()
            IronSource.setWaterfallConfiguration(configuration, for: ISAdUnit.is_AD_UNIT_INTERSTITIAL())
        }
        
        SetInfo("Loading Interstitial with floor: \(_requestedBidFloor)")
        
        _interstitialAd = LPMInterstitialAd(adUnitId: "q0z1act0tdckh4mg")
        _interstitialAd.setDelegate(self)
        _interstitialAd.loadAd()
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        ISNeftaCustomAdapter.onExternalMediationRequestFail(.interstitial, requestedFloorPrice: _requestedBidFloor, calculatedFloorPrice: _calculatedBidFloor, adUnitId: adUnitId, error: error as NSError)
        
        SetInfo("didFailToLoadAd \(adUnitId): \(error.localizedDescription)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.GetInsightsAndLoad();
        }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(.interstitial, requestedFloorPrice: _requestedBidFloor, calculatedFloorPrice: _calculatedBidFloor, adInfo: adInfo)
        
        SetInfo("didLoadAd \(adInfo.adNetwork)")
        
        _showButton.isEnabled = true
    }
    
    init(loadButton: UIButton, showButton: UIButton, status: UILabel, viewController: UIViewController) {
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
        GetInsightsAndLoad()
    }
    
    @objc func OnShowClick() {
        _showButton.isEnabled = false
        _interstitialAd.showAd(viewController: _viewController, placementName: nil)
    }
    
    func didChangeAdInfo(_ adInfo: LPMAdInfo) {
        SetInfo("didChangeAdInfo \(adInfo.adNetwork)")
    }
    
    func didFailToDisplayAd(withAdUnitId adUnitId: String, error: any Error) {
        SetInfo("didFailToDisplayAd \(adUnitId): \(error.localizedDescription)")
    }
    
    func didDisplayAd(with adInfo: LPMAdInfo) {
        SetInfo("didOpen \(adInfo.adNetwork)")
    }
    
    func didClickAd(with adInfo: LPMAdInfo) {
        SetInfo("didClick \(adInfo.adNetwork)")
    }
    
    func didCloseAd(with adInfo: LPMAdInfo) {
        SetInfo("didCloseAd \(adInfo.adNetwork)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
