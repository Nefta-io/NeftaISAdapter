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

    let _showButton: UIButton
    let _hideButton: UIButton
    let _status: UILabel
    let _viewController: UIViewController
    let _bannerPlaceholder: UIView
    
    var _bannerView: ISBannerView! = nil
    var _bannerSize: LPMAdSize!
    var _bannerAd: LPMBannerAdView!
    
    init(showButton: UIButton, hideButton: UIButton, status: UILabel, viewController: UIViewController, bannerPlaceholder: UIView) {
        _showButton = showButton
        _hideButton = hideButton
        _status = status
        _viewController = viewController
        _bannerPlaceholder = bannerPlaceholder
        
        super.init()
        
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        _hideButton.addTarget(self, action: #selector(Hide), for: .touchUpInside)
        
        _showButton.isEnabled = false
        _hideButton.isEnabled = false
    }
    
    func Create() {
        _showButton.isEnabled = true
    }
    
    @objc func Show() {
        _bannerSize = LPMAdSize.createAdaptive()

        _bannerAd = LPMBannerAdView(adUnitId: "4gyff1ux8ch1qz7y")
        _bannerAd.setAdSize(_bannerSize)
        _bannerAd.setDelegate(self)
        
        _bannerAd.loadAd(with: _viewController)
        
        _showButton.isEnabled = false
        _hideButton.isEnabled = true
    }
    
    @objc func Hide() {
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
        if _bannerAd != nil {
            _bannerAd.destroy()
            _bannerAd = nil
        }
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: Error) {
        _showButton.isEnabled = true
        _hideButton.isEnabled = false
        SetInfo("didFailToLoadAd \(Error.self)")
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        SetInfo("didLoad \(adInfo.adNetwork)")
  
        _bannerAd.frame = CGRect(x: _bannerPlaceholder.frame.size.width/2 - _bannerPlaceholder.frame.size.width/2, y: _bannerPlaceholder.frame.size.height - _bannerPlaceholder.frame.size.height, width: _bannerPlaceholder.frame.size.width, height: _bannerPlaceholder.frame.size.height - _bannerPlaceholder.safeAreaInsets.bottom * 2.5)
        _bannerPlaceholder.addSubview(_bannerAd)
    }
    
    func didFailToDisplayAd(with adInfo: LPMAdInfo, error: Error) {
        SetInfo("didFailToDisplayAd \(adInfo.adNetwork)")
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
