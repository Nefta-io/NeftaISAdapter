//
//  ViewController.swift
//  IronSourceSwiftDemoApp
//
//  Created by Alon Dotan on 19/05/2020.
//  Copyright © 2017 ironsrc. All rights reserved.
//

import UIKit
import Foundation
import ObjectiveC.runtime
import IronSource
import NeftaSDK

let kAPPKEY = "1c0431145"

class ViewController: UIViewController, ISImpressionDataDelegate {
    
    var _banner: Banner!
    var _interstitial: Interstitial!
    var _rewardedVideo: RewardedVideo!
    
    @IBOutlet weak var _bannerPlaceholder: UIView!
    @IBOutlet weak var _showBanner: UIButton!
    @IBOutlet weak var _hideBanner: UIButton!
    @IBOutlet weak var _loadInterstitial: UIButton!
    @IBOutlet weak var _showInterstitial: UIButton!
    @IBOutlet weak var _loadRewarded: UIButton!
    @IBOutlet weak var _showRewarded: UIButton!
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _bannerStatus: UILabel!
    @IBOutlet weak var _interstitialStatus: UILabel!
    @IBOutlet weak var _rewardedStatus: UILabel!
    @IBOutlet weak var _impressionStatus: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NeftaPlugin.EnableLogging(enable: true)
        _ = NeftaPlugin.Init(appId: "5661184053215232")
        
        _title.text = "Nefta Adapter for\n IronSource \(IronSource.sdkVersion())"
        
        _banner = Banner(showButton: _showBanner, hideButton: _hideBanner, status: _bannerStatus, viewController: self, bannerPlaceholder: _bannerPlaceholder)
        _interstitial = Interstitial(loadButton: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus, viewController: self)
        _rewardedVideo = RewardedVideo(loadButton: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus, viewController: self)
        
        let requestBuilder = LPMInitRequestBuilder(appKey: kAPPKEY)
            .withLegacyAdFormats([IS_REWARDED_VIDEO])
        let initRequest = requestBuilder.build()
        LevelPlay.initWith(initRequest)
        { config, error in

            guard error == nil else {
                print("sdk initialization failed, error =\(error?.localizedDescription ?? "unknown error")")
                return
            }
            print("sdk initialization succeeded")
            self._banner.Create()
            self._interstitial.Create()
        }
    }
    
    func impressionDataDidSucceed(_ impressionData: ISImpressionData!) {
        let status = "impressionDataDidSucceed \(String(describing: impressionData))"
        print(status)
        _impressionStatus.text = status
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

