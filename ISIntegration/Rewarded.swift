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
    
    private let FloorPriceInsightName = "calculated_user_floor_price_rewarded"
    
    private var _bidFloor: Double = 0.0
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested: Bool = false

    let _loadButton: UIButton
    let _showButton: UIButton
    let _status: UILabel
    let _viewController: UIViewController
    
    var _rewarded: LPMRewardedAd!
    
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
        
        print("OnBehaviourInsight for Rewarded calculated bid floor: \(_calculatedBidFloor)")
        
        if _isLoadRequested {
            Load()
        }
    }
    
    func Load() {
        _isLoadRequested = false
        
        if _calculatedBidFloor == 0 {
            _bidFloor = 0
            IronSource.setWaterfallConfiguration(ISWaterfallConfiguration.clear(), for: ISAdUnit.is_AD_UNIT_REWARDED_VIDEO())
        } else {
            _bidFloor = _calculatedBidFloor
            let configuration = ISWaterfallConfiguration.builder()
                .setFloor(NSNumber(value: _bidFloor))
                .build()
            IronSource.setWaterfallConfiguration(configuration, for: ISAdUnit.is_AD_UNIT_REWARDED_VIDEO())
        }
        
        SetInfo("Loading Rewarded with floor: \(_bidFloor)")
        
        _rewarded = LPMRewardedAd(adUnitId: "doucurq8qtlnuz7p")
        _rewarded.setDelegate(self)
        _rewarded.loadAd()
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        ISNeftaCustomAdapter.onExternalMediationRequestFail(.rewarded, requestedFloorPrice: _bidFloor, calculatedFloorPrice: _calculatedBidFloor, adUnitId: adUnitId, error: error as NSError)
        
        SetInfo("didFailToLoadAd \(adUnitId): \(error.localizedDescription)")
        
        // or automatically retry with a delay
        // DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        //     self.GetInsightsAndLoad()
        // }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(.rewarded, requestedFloorPrice: _bidFloor, calculatedFloorPrice: _calculatedBidFloor, adInfo: adInfo)
        
        SetInfo("didLoadAd \(adInfo)")
        
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
        
        _showButton.isEnabled = false
    }
    
    @objc func OnLoadClick() {
        GetInsightsAndLoad()
    }
    
    @objc func OnShowClick() {
        _showButton.isEnabled = false
        _rewarded.showAd(viewController: _viewController, placementName: nil)
    }
    
    func didRewardAd(with adInfo: LPMAdInfo, reward: LPMReward) {
        SetInfo("didRewardAd \(adInfo)")
    }
    
    func didReceiveReward(forPlacement placementInfo: ISPlacementInfo!, with adInfo: ISAdInfo!) {
        SetInfo("didReceiveReward \(adInfo.ad_network)")
    }
    
    func didFailToShowWithError(_ error: (any Error)!, andAdInfo adInfo: ISAdInfo!) {
        SetInfo("didFailToShowWithError \(String(describing: error.self))")
    }
    
    func didDisplayAd(with adInfo: LPMAdInfo) {
        SetInfo("didDisplayAd \(adInfo)")
    }
    
    func didClickAd(with adInfo: LPMAdInfo) {
        SetInfo("didClick \(String(describing: adInfo))")
    }
    
    func didCloseAd(with adInfo: LPMAdInfo) {
        SetInfo("didOpen \(String(describing: adInfo))")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
