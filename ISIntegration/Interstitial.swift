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
    
    private let _loadButton: UIButton
    private let _showButton: UIButton
    private let _status: UILabel
    private var _viewController: UIViewController
    private var _isLoading = false
    
    private var _interstitialAd: LPMInterstitialAd!
    private var _usedInsight: AdInsight?
    private var _requestedFloorPrice: Double = 0
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Interstitial, callback: Load, timeout: 5)
    }
    
    private func Load(insights: Insights) {
        _requestedFloorPrice = 0
        _usedInsight = insights._interstitial
        if let usedInsight = _usedInsight {
            _requestedFloorPrice = usedInsight._floorPrice
        }
        
        SetInfo("Loading Interstitial with floor: \(_requestedFloorPrice)")
        
        let config = LPMInterstitialAdConfigBuilder()
            .set(bidFloor: _requestedFloorPrice as NSNumber)
            .build()
        
        _interstitialAd = LPMInterstitialAd(adUnitId: "q0z1act0tdckh4mg", config: config)
        _interstitialAd.setDelegate(self)
        _interstitialAd.loadAd()
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        ISNeftaCustomAdapter.onExternalMediationRequestFail(.interstitial, usedInsight: _usedInsight, requestedFloorPrice: _requestedFloorPrice, adUnitId: adUnitId, error: error as NSError)
        
        SetInfo("didFailToLoadAd \(adUnitId): \(error.localizedDescription)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self._isLoading {
                self.GetInsightsAndLoad()
            }
        }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(.interstitial, usedInsight: _usedInsight, requestedFloorPrice: _requestedFloorPrice, adInfo: adInfo)
        
        SetInfo("didLoadAd \(adInfo.adNetwork)")
        
        SetLoadingButton(isLoading: false)
        _loadButton.isEnabled = false
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
        if _isLoading {
            SetLoadingButton(isLoading: false)
        } else {
            SetInfo("GetInsightsAndLoad...")
            GetInsightsAndLoad()
            SetLoadingButton(isLoading: true)
        }
    }
    
    @objc func OnShowClick() {
        _interstitialAd.showAd(viewController: _viewController, placementName: nil)
        
        _loadButton.isEnabled = true
        _showButton.isEnabled = false
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
    
    private func SetLoadingButton(isLoading: Bool) {
        _isLoading = isLoading
        if isLoading {
            _loadButton.setTitle("Cancel", for: .normal)
        } else {
            _loadButton.setTitle("Load Interstitial", for: .normal)
        }
    }
}
