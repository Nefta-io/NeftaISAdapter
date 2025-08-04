//
//  ViewController.swift
//  IronSourceSwiftDemoApp
//
//  Created by Alon Dotan on 19/05/2020.
//  Copyright © 2017 ironsrc. All rights reserved.
//

import UIKit
import Foundation
import IronSource
import NeftaSDK

let kAPPKEY = "1c0431145"

class ViewController: UIViewController {
    
    var _banner: Banner!
    var _interstitial: Interstitial!
    var _rewardedVideo: Rewarded!
    
    @IBOutlet weak var _bannerPlaceholder: UIView!
    @IBOutlet weak var _demandControl: UISegmentedControl!
    @IBOutlet weak var _testSuite: UIButton!
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
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1 {
            NeftaPlugin.SetOverride(url: arguments[1])
        }
        
        let plugin = ISNeftaCustomAdapter.initWithAppId("5759667955302400")
        
        _title.text = "Nefta Adapter for\n IronSource \(LevelPlay.sdkVersion())"
        
        _banner = Banner(loadAndShowButton: _showBanner, closeButton: _hideBanner, status: _bannerStatus, viewController: self, bannerPlaceholder: _bannerPlaceholder)
        _interstitial = Interstitial(loadButton: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus, viewController: self)
        _rewardedVideo = Rewarded(loadButton: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus, viewController: self)
        
        LevelPlay.setMetaDataWithKey("is_test_suite", value: "enable")
        
        let requestBuilder = LPMInitRequestBuilder(appKey: kAPPKEY)
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
            self._rewardedVideo.Create()
        }
        
        _demandControl.addTarget(self, action: #selector(onDemandChanged(_:)), for: .valueChanged)
        _testSuite.addTarget(self, action: #selector(onTestSuite), for: .touchUpInside)
        
        SetSegment(isIs: true)
    }
    
    @objc func onTestSuite() {
        LevelPlay.launchTestSuite(self)
    }
    
    @IBAction func onDemandChanged(_ sender: UISegmentedControl) {
        SetSegment(isIs: _demandControl.selectedSegmentIndex == 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func SetSegment(isIs: Bool) {
        let demandSegment = LPMSegment()
        demandSegment.segmentName = isIs ? "is" : "nefta"
        LevelPlay.setSegment(demandSegment)
    }
}

