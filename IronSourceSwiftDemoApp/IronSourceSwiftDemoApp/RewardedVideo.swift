//
//  RewardedVideo.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 19. 06. 24.
//  Copyright © 2024 ironsrc. All rights reserved.
//

import Foundation
import IronSource

class RewardedVideo : NSObject, LevelPlayRewardedVideoDelegate {
    
    let _loadButton: UIButton
    let _showButton: UIButton
    let _status: UILabel
    let _viewController: UIViewController
    
    init(loadButton: UIButton, showButton: UIButton, status: UILabel, viewController: ViewController) {
        _loadButton = loadButton
        _showButton = showButton
        _status = status
        _viewController = viewController
        
        super.init()
        
        _loadButton.addTarget(self, action: #selector(Load), for: .touchUpInside)
        _showButton.addTarget(self, action: #selector(Show), for: .touchUpInside)
        
        IronSource.setLevelPlayRewardedVideoDelegate(self)
        
        _showButton.isEnabled = false
    }
    
    @objc func Load() {
        IronSource.loadRewardedVideo()
    }
    
    @objc func Show() {
        IronSource.showRewardedVideo(with: _viewController)
    }
    
    func hasAvailableAd(with adInfo: ISAdInfo!) {
        SetInfo("hasAvailableAd \(adInfo.ad_network)")
        _showButton.isEnabled = true
    }
    
    func hasNoAvailableAd() {
        SetInfo("hasNoAvailableAd")
        _showButton.isEnabled = false
    }
    
    func didReceiveReward(forPlacement placementInfo: ISPlacementInfo!, with adInfo: ISAdInfo!) {
        SetInfo("didReceiveReward \(adInfo.ad_network)")
    }
    
    func didFailToShowWithError(_ error: (any Error)!, andAdInfo adInfo: ISAdInfo!) {
        SetInfo("didFailToShowWithError \(String(describing: error.self))")
    }
    
    func didOpen(with adInfo: ISAdInfo!) {
        SetInfo("didOpen \(adInfo.ad_network)")
    }
    
    func didClick(_ placementInfo: ISPlacementInfo!, with adInfo: ISAdInfo!) {
        SetInfo("didClick \(adInfo.ad_network)")
    }
    
    func didClose(with adInfo: ISAdInfo!) {
        SetInfo("didOpen \(adInfo.ad_network)")
    }
    
    private func SetInfo(_ info: String) {
        print(info)
        _status.text = info
    }
}
