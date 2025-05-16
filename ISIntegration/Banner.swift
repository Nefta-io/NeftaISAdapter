//
//  Banner.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

import Foundation
import IronSource

class Banner: NSObject, LPMBannerAdViewDelegate {
    private let FloorPriceInsightName = "calculated_user_floor_price_banner"
    
    private var _bidFloor: Double = 0.0
    private var _calculatedBidFloor: Double = 0.0
    private var _isLoadRequested = false
    
    private let _loadAndShowButton: UIButton
    private let _closeButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    private let _bannerPlaceholder: UIView
    
    private var _bannerView: ISBannerView! = nil
    private var _bannerAd: LPMBannerAdView!
    
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
    
    private func OnBehaviourInsight(insights: [String: Insight]) {
        _calculatedBidFloor = 0
        if let bidFloorInsight = insights[FloorPriceInsightName] {
            _calculatedBidFloor = bidFloorInsight._float
        }
        
        print("OnBehaviourInsight for Banner calculated bid floor: \(_calculatedBidFloor)")
        
        if _isLoadRequested {
            Load()
        }
    }
    
    private func Load() {
        _isLoadRequested = false
        
        if _calculatedBidFloor <= 0 {
            _bidFloor = 0
            IronSource.setWaterfallConfiguration(ISWaterfallConfiguration.clear(), for: ISAdUnit.is_AD_UNIT_BANNER())
        } else {
            _bidFloor = _calculatedBidFloor
            let configuration = ISWaterfallConfiguration.builder()
                .setFloor(NSNumber(value: _bidFloor))
                .build()
            IronSource.setWaterfallConfiguration(configuration, for: ISAdUnit.is_AD_UNIT_BANNER())
        }
        
        SetInfo("Loading Banner with floor: \(_bidFloor)")
    
        _bannerAd = LPMBannerAdView(adUnitId: "4gyff1ux8ch1qz7y")
        _bannerAd.setAdSize(LPMAdSize.banner())
        _bannerAd.setDelegate(self)
        
        _bannerAd.loadAd(with: _viewController)
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        ISNeftaCustomAdapter.onExternalMediationRequestFail(.banner, requestedFloorPrice: _bidFloor, calculatedFloorPrice: _calculatedBidFloor, adUnitId: adUnitId, error: error as NSError)
        
        SetInfo("didFailToLoadAd \(error.localizedDescription)")
        
        _loadAndShowButton.isEnabled = true
        _closeButton.isEnabled = false
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(.banner, requestedFloorPrice: _bidFloor, calculatedFloorPrice: _calculatedBidFloor, adInfo: adInfo)
 
        SetInfo("didLoad \(adInfo.adNetwork)")
  
        _bannerAd.frame = CGRect(x: _bannerPlaceholder.frame.size.width * 0.5 - _bannerPlaceholder.frame.size.width * 0.5, y: _bannerPlaceholder.frame.size.height - _bannerPlaceholder.frame.size.height, width: _bannerPlaceholder.frame.size.width, height: _bannerPlaceholder.frame.size.height - _bannerPlaceholder.safeAreaInsets.bottom * 2.5)
        _bannerPlaceholder.addSubview(_bannerAd)
    }
    
    init(loadAndShowButton: UIButton, closeButton: UIButton, status: UILabel, viewController: UIViewController, bannerPlaceholder: UIView) {
        _loadAndShowButton = loadAndShowButton
        _closeButton = closeButton
        _status = status
        _viewController = viewController
        _bannerPlaceholder = bannerPlaceholder
        
        super.init()
        
        _loadAndShowButton.addTarget(self, action: #selector(OnLoadClick), for: .touchUpInside)
        _closeButton.addTarget(self, action: #selector(OnCloseClick), for: .touchUpInside)
        
        _loadAndShowButton.isEnabled = false
        _closeButton.isEnabled = false
    }
    
    func Create() {
        _loadAndShowButton.isEnabled = true
    }
    
    @objc func OnLoadClick() {
        GetInsightsAndLoad()
        
        SetInfo("Loading...")
        
        _loadAndShowButton.isEnabled = false
        _closeButton.isEnabled = true
    }
    
    @objc func OnCloseClick() {
        if _bannerAd != nil {
            _bannerAd.destroy()
            _bannerAd = nil
        }
        
        SetInfo("Closing Banner")
        
        _loadAndShowButton.isEnabled = true
        _closeButton.isEnabled = false
    }
    
    func didFailToDisplayAd(with adInfo: LPMAdInfo, error: any Error) {
        SetInfo("didFailToDisplayAd \(adInfo.adNetwork): \(error.localizedDescription)")
    }
    
    func didDisplayAd(with adInfo: LPMAdInfo) {
        SetInfo("didDisplayAd \(adInfo.adNetwork)")
    }
    
    func didClick(with adInfo: LPMAdInfo) {
        SetInfo("didClick \(adInfo.adNetwork)")
    }
    
    func didClickAd(with adInfo: LPMAdInfo) {
        SetInfo("didClickAd \(adInfo.adNetwork)")
    }
    
    func didLeaveApp(with adInfo: LPMAdInfo) {
        SetInfo("didLeaveApp \(adInfo.adNetwork)")
    }
    
    func didCollapseAd(with adInfo: LPMAdInfo) {
        SetInfo("didCollapseAd \(adInfo.adNetwork)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
