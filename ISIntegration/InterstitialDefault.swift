//
//  InterstitialDefault.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 9. 5. 26.
//  Copyright © 2026 ironsrc. All rights reserved.
//

class InterstitialDefault : NSObject, LPMInterstitialAdDelegate, Interstitial {
    
    var _ui: InterstitialUi!
    
    var _interstitial: LPMInterstitialAd!
    
    func Init(ui: InterstitialUi) {
        _ui = ui
        
        _interstitial = LPMInterstitialAd(adUnitId: InterstitialUi.AdUnitA)
        _interstitial!.setDelegate(self)
    }
    
    public func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
        let lpError = error as NSError
        ISNeftaCustomAdapter.onExternalMediationRequestFail(lpError)
        
        Log("Load failed \(adUnitId): \(error.localizedDescription)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self._ui.IsAutoLoad {
                self.Load()
            }
        }
    }
    
    public func didLoadAd(with adInfo: LPMAdInfo) {
        ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
        
        Log("didload \(adInfo.adUnitId)")
        
        _ui.SetAvailable(available: true)
    }
    
    public func didClickAd(with adInfo: LPMAdInfo) {
        Log("didClick \(adInfo.adNetwork)")
        
        ISNeftaCustomAdapter.onExternalMediationClick(adInfo)
    }
    
    func didFailToDisplayAd(withAdUnitId adUnitId: String, error: any Error) {
        Log("didFailToDisplayAd \(adUnitId): \(error.localizedDescription)")
        
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    public func didDisplayAd(with adInfo: LPMAdInfo) {
        Log("didOpen \(adInfo.adNetwork)")
    }
    
    public func didCloseAd(with adInfo: LPMAdInfo) {
        Log("didCloseAd \(adInfo.adNetwork)")
        
        if _ui.IsAutoLoad {
            Load()
        }
    }
    
    public func Load() {
        ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: _interstitial, adUnitId: InterstitialUi.AdUnitA, insight: nil)
        _interstitial.loadAd()
    }
    
    public func Show() {
        if _interstitial.isAdReady() {
            _interstitial.showAd(viewController: _ui.ViewController, placementName: nil)
        } else if _ui.IsAutoLoad {
            Load()
        }
        
        _ui.SetAvailable(available: false)
    }
    
    private func Log(_ log: String) {
        _ui.Log(log)
    }
}
