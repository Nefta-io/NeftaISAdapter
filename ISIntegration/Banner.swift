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
    
    private let _loadAndShowButton: UIButton
    private let _closeButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    private let _bannerPlaceholder: UIView
    
    private var _bannerView: LPMBannerAdView! = nil
    private var _bannerAd: LPMBannerAdView!
    private var _usedInsight: AdInsight?
    private var _requestedFloorPrice: Double = 0
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Banner, callback: Load, timeout: 5)
    }
    
    private func Load(insights: Insights) {
        _requestedFloorPrice = 0
        _usedInsight = insights._banner
        if let usedInsight = _usedInsight {
            _requestedFloorPrice = usedInsight._floorPrice
        }
    
        SetInfo("Loading Banner with floor: \(_requestedFloorPrice)")
    
        let config = LPMBannerAdViewConfigBuilder()
            .set(adSize: LPMAdSize.banner())
            .set(bidFloor: _requestedFloorPrice as NSNumber)
            .build()
        
        _bannerAd = LPMBannerAdView(adUnitId: "4gyff1ux8ch1qz7y", config: config)
        _bannerAd.setDelegate(self)
        
        _bannerAd.loadAd(with: _viewController)
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        ISNeftaCustomAdapter.onExternalMediationRequestFail(.banner, usedInsight: _usedInsight, requestedFloorPrice: _requestedFloorPrice, adUnitId: adUnitId, error: error as NSError)
        
        SetInfo("didFailToLoadAd \(error.localizedDescription)")
        
        _loadAndShowButton.isEnabled = true
        _closeButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.GetInsightsAndLoad()
        }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(.banner, usedInsight: _usedInsight, requestedFloorPrice: _requestedFloorPrice, adInfo: adInfo)
        
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
        SetInfo("GetInsightsAndLoad...")
        GetInsightsAndLoad()
        
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
