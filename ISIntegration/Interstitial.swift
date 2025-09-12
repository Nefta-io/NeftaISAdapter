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
    private let _dynamicAdUnitId = "g7xalw41x4i1bj5t"
    private let _defaultAdUnitId = "q0z1act0tdckh4mg"
    
    private var _dynamicInterstitial: LPMInterstitialAd?
    private var _dynamicAdRevenue: Float64 = -1
    private var _dynamicInsight: AdInsight?
    private var _defaultInterstitial: LPMInterstitialAd?
    private var _defaultAdRevenue: Float64 = -1
    private var _presentingInterstitial: LPMInterstitialAd?
    
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    private let _status: UILabel
    private var _viewController: UIViewController
    
    private func StartLoading() {
        if _dynamicInterstitial == nil {
            GetInsightsAndLoad(previousInsight: nil)
        }
        if _defaultInterstitial == nil {
            LoadDefault()
        }
    }
    
    private func GetInsightsAndLoad(previousInsight: AdInsight?) {
        NeftaPlugin._instance.GetInsights(Insights.Interstitial, previousInsight: previousInsight, callback: LoadWithInsights, timeout: 5)
    }
    
    private func LoadWithInsights(insights: Insights) {
        _dynamicInsight = insights._interstitial
        if let insight = _dynamicInsight {
            SetInfo("Loading Dynamic with floor: \(insight._floorPrice)")
            
            let config = LPMInterstitialAdConfigBuilder()
                .set(bidFloor: insight._floorPrice as NSNumber)
                .build()
            _dynamicInterstitial = LPMInterstitialAd(adUnitId: _dynamicAdUnitId, config: config)
            _dynamicInterstitial!.setDelegate(self)
            _dynamicInterstitial!.loadAd()
            
            ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: _dynamicInterstitial!, adUnitId: _dynamicAdUnitId, insight: _dynamicInsight)
        }
    }
    
    private func LoadDefault() {
        SetInfo("Loading Default")
        
        _defaultInterstitial = LPMInterstitialAd(adUnitId: _defaultAdUnitId)
        _defaultInterstitial!.setDelegate(self)
        _defaultInterstitial!.loadAd()
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: _defaultInterstitial!, adUnitId: _defaultAdUnitId, insight: nil)
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        let lpError = error as NSError
        ISNeftaCustomAdapter.onExternalMediationRequestFail(lpError)
        
        if _dynamicInterstitial != nil && _dynamicInterstitial!.adId == lpError.userInfo["adId"] as? String {
            SetInfo("Load Dynamic failed \(adUnitId): \(error.localizedDescription)")
            
            _dynamicInterstitial = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self._loadSwitch.isOn {
                    self.GetInsightsAndLoad(previousInsight: self._dynamicInsight)
                }
            }
        } else {
            SetInfo("Load Default failed \(adUnitId): \(error.localizedDescription)")
            
            _defaultInterstitial = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self._loadSwitch.isOn {
                    self.LoadDefault()
                }
            }
        }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
        
        if _dynamicInterstitial != nil && _dynamicInterstitial!.adId == adInfo.adId {
            SetInfo("didLoadAd Dynamic \(adInfo)")
            
            _dynamicAdRevenue = adInfo.revenue.doubleValue;
        } else {
            SetInfo("didLoadAd Default \(adInfo)")
            
            _defaultAdRevenue = adInfo.revenue.doubleValue;
        }
        
        UpdateShowButton()
    }
    
    func didClickAd(with adInfo: LPMAdInfo) {
        SetInfo("didClick \(adInfo.adNetwork)")
        
        ISNeftaCustomAdapter.onExternalMediationClick(adInfo)
    }
    
    init(loadSwitch: UISwitch, showButton: UIButton, status: UILabel, viewController: UIViewController) {
        _loadSwitch = loadSwitch
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _loadSwitch.isEnabled = false
        _showButton.isEnabled = false
    }
    
    func Create() {
        _loadSwitch.isEnabled = true
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            StartLoading()
        }
    }
    
    @objc func OnShowClick() {
        var isShown = false
        if _dynamicAdRevenue >= 0 {
            if _defaultAdRevenue > _dynamicAdRevenue {
                isShown = TryShowDefault()
            }
            if !isShown {
                isShown = TryShowDynamic()
            }
        }
        if !isShown && _defaultAdRevenue >= 0 {
            isShown = TryShowDefault()
        }
        
        UpdateShowButton()
    }
    
    private func TryShowDynamic() -> Bool {
        var isShown = false
        if _dynamicInterstitial!.isAdReady() {
            _dynamicInterstitial!.showAd(viewController: _viewController, placementName: nil)
            isShown = true
        }
        _dynamicAdRevenue = -1
        _presentingInterstitial = _dynamicInterstitial
        _dynamicInterstitial = nil
        return isShown
    }
    
    private func TryShowDefault() -> Bool {
        var isShown = false;
        if _defaultInterstitial!.isAdReady() {
            _defaultInterstitial!.showAd(viewController: _viewController, placementName: nil)
            isShown = true
        }
        _defaultAdRevenue = -1
        _presentingInterstitial = _defaultInterstitial
        _defaultInterstitial = nil
        return isShown
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
    
    func didCloseAd(with adInfo: LPMAdInfo) {
        SetInfo("didCloseAd \(adInfo.adNetwork)")
        _presentingInterstitial = nil
        
        // start new load cycle
        if (_loadSwitch.isOn) {
            StartLoading();
        }
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _dynamicAdRevenue >= 0 || _defaultAdRevenue >= 0
    }
    
    private func SetInfo(_ info: String) {
        print("NeftaPluginIS Interstitial \(info)")
        _status.text = info
    }
}
