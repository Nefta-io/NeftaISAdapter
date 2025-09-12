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
    private let _dynamicAdUnitId = "p3dh8r1mm3ua8fvv"
    private let _defaultAdUnitId = "doucurq8qtlnuz7p"
    
    private var _dynamicRewarded: LPMRewardedAd?
    private var _dynamicAdRevenue: Float64 = -1
    private var _dynamicInsight: AdInsight?
    private var _defaultRewarded: LPMRewardedAd?
    private var _defaultAdRevenue: Float64 = -1
    private var _presentingRewarded: LPMRewardedAd?
    
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    
    private func StartLoading() {
        if _dynamicRewarded == nil {
            GetInsightsAndLoad(previousInsight: nil)
        }
        if _defaultRewarded == nil {
            LoadDefault()
        }
    }
    
    private func GetInsightsAndLoad(previousInsight: AdInsight?) {
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, previousInsight: previousInsight, callback: LoadWithInsights, timeout: 5)
    }
    
    private func LoadWithInsights(insights: Insights) {
        _dynamicInsight = insights._rewarded
        if let insight = _dynamicInsight {
            SetInfo("Loading Dynamic with floor: \(insight._floorPrice)")
            
            let config = LPMRewardedAdConfigBuilder()
                .set(bidFloor: insight._floorPrice as NSNumber)
                .build()
            _dynamicRewarded = LPMRewardedAd(adUnitId: _dynamicAdUnitId, config: config)
            _dynamicRewarded!.setDelegate(self)
            _dynamicRewarded!.loadAd()
            
            ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: _dynamicRewarded!, adUnitId: _dynamicAdUnitId, insight: _dynamicInsight)
        }
    }
    
    private func LoadDefault() {
        SetInfo("Loading Default")
        
        _defaultRewarded = LPMRewardedAd(adUnitId: _defaultAdUnitId)
        _defaultRewarded!.setDelegate(self)
        _defaultRewarded!.loadAd()
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: _defaultRewarded!, adUnitId: _defaultAdUnitId, insight: nil)
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        let lpError = error as NSError
        ISNeftaCustomAdapter.onExternalMediationRequestFail(lpError)
        
        if _dynamicRewarded != nil && _dynamicRewarded!.adId == lpError.userInfo["adId"] as! String {
            SetInfo("Load Dynamic failed \(adUnitId): \(error.localizedDescription)")
            
            _dynamicRewarded = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self._loadSwitch.isOn {
                    self.GetInsightsAndLoad(previousInsight: self._dynamicInsight)
                }
            }
        } else {
            SetInfo("Load Default failed \(adUnitId): \(error.localizedDescription)")
            
            _defaultRewarded = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self._loadSwitch.isOn {
                    self.LoadDefault()
                }
            }
        }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
        
        if _dynamicRewarded != nil && _dynamicRewarded!.adId == adInfo.adId {
            SetInfo("didLoadAd Dynamic \(adInfo)")
            
            _dynamicAdRevenue = adInfo.revenue.doubleValue;
        } else {
            SetInfo("didLoadAd Default \(adInfo)")
            
            _defaultAdRevenue = adInfo.revenue.doubleValue;
        }
        
        UpdateShowButton()
    }
    
    func didClickAd(with adInfo: LPMAdInfo) {
        SetInfo("didClickAd \(String(describing: adInfo))")
        
        ISNeftaCustomAdapter.onExternalMediationClick(adInfo)
    }
    
    init(loadSwitch: UISwitch, showButton: UIButton, status: UILabel, viewController: ViewController) {
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
        if _dynamicRewarded!.isAdReady() {
            _dynamicRewarded!.showAd(viewController: _viewController, placementName: nil)
            isShown = true
        }
        _dynamicAdRevenue = -1
        _presentingRewarded = _dynamicRewarded
        _dynamicRewarded = nil
        return isShown
    }
    
    private func TryShowDefault() -> Bool {
        var isShown = false;
        if _defaultRewarded!.isAdReady() {
            _defaultRewarded!.showAd(viewController: _viewController, placementName: nil)
            isShown = true
        }
        _defaultAdRevenue = -1
        _presentingRewarded = _defaultRewarded
        _defaultRewarded = nil
        return isShown
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
    
    func didCloseAd(with adInfo: LPMAdInfo) {
        SetInfo("didCloseAd \(String(describing: adInfo))")
        _presentingRewarded = nil
        
        // start new load cycle
        if (_loadSwitch.isOn) {
            StartLoading();
        }
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _dynamicAdRevenue >= 0 || _defaultAdRevenue >= 0
    }
    
    private func SetInfo(_ info: String) {
        print("NeftaPluginIS Rewarded \(info)")
        _status.text = info
    }
}
