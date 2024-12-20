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
    
    let _loadButton: UIButton
    let _showButton: UIButton
    let _status: UILabel
    var _viewController: UIViewController
    
    var _interstitialAd: LPMInterstitialAd!
    
    init(loadButton: UIButton, showButton: UIButton, status: UILabel, viewController: UIViewController) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(Load), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        
        _loadButton.isEnabled = false
        _showButton.isEnabled = false
    }
    
    func Create() {
        _loadButton.isEnabled = true
    }
    
    @objc func Load() {
        _interstitialAd = LPMInterstitialAd(adUnitId: "q0z1act0tdckh4mg")
        _interstitialAd.setDelegate(self)
        _interstitialAd.loadAd()
    }
    
    @objc func Show() {
        _showButton.isEnabled = false
        _interstitialAd.showAd(viewController: _viewController, placementName: nil)
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: Error) {
        SetInfo("didFailToShowWithError \(adUnitId): \(String(describing: error))")
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        _showButton.isEnabled = true
        SetInfo("didLoad \(adInfo.adNetwork)")
    }
    
    func didChangeAdInfo(_ adInfo: LPMAdInfo) {
        SetInfo("didChangeAdInfo \(adInfo.adNetwork)")
    }
    
    func didFailToDisplayAd(with adInfo: LPMAdInfo, error: Error) {
        SetInfo("didFailToDisplayAd \(adInfo) \(String(describing: error))")
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
