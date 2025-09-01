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
    
    private var _dynamicRewarded: LPMRewardedAd!
    private var _isDynamicLoaded = false
    private var _dynamicAdUnitInsight: AdInsight?
    private var _defaultRewarded: LPMRewardedAd!
    private var _isDefaultLoaded = false
    
    private let _loadSwitch: UISwitch
    private let _showButton: UIButton
    private let _status: UILabel
    private let _viewController: UIViewController
    
    private func StartLoading() {
        if _dynamicRewarded == nil {
            GetInsightsAndLoad()
        }
        if _defaultRewarded == nil {
            LoadDefault()
        }
    }
    
    private func GetInsightsAndLoad() {
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, callback: LoadWithInsights, timeout: 5)
    }
    
    private func LoadWithInsights(insights: Insights) {
        _dynamicAdUnitInsight = insights._rewarded
        if let insight = _dynamicAdUnitInsight {
            SetInfo("Loading Dynamic Rewarded with floor: \(insight._floorPrice)")
            
            let config = LPMRewardedAdConfigBuilder()
                .set(bidFloor: insight._floorPrice as NSNumber)
                .build()
            _dynamicRewarded = LPMRewardedAd(adUnitId: _dynamicAdUnitId, config: config)
            _dynamicRewarded.setDelegate(self)
            _dynamicRewarded.loadAd()
        }
    }
    
    private func LoadDefault() {
        SetInfo("Loading Default Rewarded")
        
        _defaultRewarded = LPMRewardedAd(adUnitId: _defaultAdUnitId)
        _defaultRewarded.setDelegate(self)
        _defaultRewarded.loadAd()
    }
    
    func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        if adUnitId == _dynamicAdUnitId {
            ISNeftaCustomAdapter.onExternalMediationRequestFail(.rewarded, usedInsight: _dynamicAdUnitInsight, requestedFloorPrice: _dynamicAdUnitInsight!._floorPrice, adUnitId: adUnitId, error: error as NSError)
            
            SetInfo("didFailToLoadAd Dynamic \(adUnitId): \(error.localizedDescription)")
            
            _dynamicRewarded = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self._loadSwitch.isOn {
                    self.GetInsightsAndLoad()
                }
            }
        } else {
            ISNeftaCustomAdapter.onExternalMediationRequestFail(.rewarded, usedInsight: nil, requestedFloorPrice: 0, adUnitId: adUnitId, error: error as NSError)
            
            SetInfo("didFailToLoadAd Default \(adUnitId): \(error.localizedDescription)")
            
            _defaultRewarded = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self._loadSwitch.isOn {
                    self.LoadDefault()
                }
            }
        }
    }
    
    func didLoadAd(with adInfo: LPMAdInfo) {
        if adInfo.adUnitId == _dynamicAdUnitId {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(.rewarded, usedInsight: _dynamicAdUnitInsight, requestedFloorPrice: _dynamicAdUnitInsight!._floorPrice, adInfo: adInfo)
            
            SetInfo("didLoadAd Dynamic \(adInfo)")
            
            _isDynamicLoaded = true;
        } else {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(.rewarded, usedInsight: nil, requestedFloorPrice: 0, adInfo: adInfo)
            
            SetInfo("didLoadAd Default \(adInfo)")
            
            _isDefaultLoaded = true;
        }
        
        UpdateShowButton()
    }
    
    init(loadButton: UISwitch, showButton: UIButton, status: UILabel, viewController: ViewController) {
        _loadSwitch = loadButton
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
        if _isDynamicLoaded {
            if _dynamicRewarded!.isAdReady() {
                _dynamicRewarded.showAd(viewController: _viewController, placementName: nil)
                isShown = true
            }
            _isDynamicLoaded = false
            _dynamicRewarded = nil
        }
        if !isShown && _isDefaultLoaded {
            if _defaultRewarded!.isAdReady() {
                _defaultRewarded.showAd(viewController: _viewController, placementName: nil)
            }
            _isDefaultLoaded = false
            _defaultRewarded = nil
        }
        
        UpdateShowButton()
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
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
    
    func UpdateShowButton() {
        _showButton.isEnabled = _isDynamicLoaded || _isDefaultLoaded
    }
}
