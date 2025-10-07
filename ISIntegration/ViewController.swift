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
    
    var _interstitial: Interstitial!
    var _rewardedVideo: Rewarded!
    
    @IBOutlet weak var _demandControl: UISegmentedControl!
    @IBOutlet weak var _testSuite: UIButton!
    @IBOutlet weak var _loadInterstitial: UISwitch!
    @IBOutlet weak var _showInterstitial: UIButton!
    @IBOutlet weak var _loadRewarded: UISwitch!
    @IBOutlet weak var _showRewarded: UIButton!
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _interstitialStatus: UILabel!
    @IBOutlet weak var _rewardedStatus: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = DebugServer(viewController: self)
        
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.count > 1 {
            NeftaPlugin.SetOverride(url: arguments[1])
        }
        
        NeftaPlugin.EnableLogging(enable: true)
        NeftaPlugin.SetExtraParameter(key: NeftaPlugin.ExtParam_TestGroup, value: "split-is")
        let plugin = ISNeftaCustomAdapter.initWithAppId("5759667955302400", sendImpressions: false)
        
        _title.text = "Nefta Adapter for\n IronSource \(LevelPlay.sdkVersion())"
        
        _interstitial = Interstitial(loadSwitch: _loadInterstitial, showButton: _showInterstitial, status: _interstitialStatus, viewController: self)
        _rewardedVideo = Rewarded(loadSwitch: _loadRewarded, showButton: _showRewarded, status: _rewardedStatus, viewController: self)
        
        LevelPlay.setMetaDataWithKey("is_test_suite", value: "enable")
        LevelPlay.add(ISNeftaImpressionCollector())
        
        let requestBuilder = LPMInitRequestBuilder(appKey: kAPPKEY)
        let initRequest = requestBuilder.build()
        LevelPlay.initWith(initRequest)
        { config, error in
            guard error == nil else {
                print("NeftaPluginIS sdk initialization failed, error =\(error?.localizedDescription ?? "unknown error")")
                return
            }
            print("NeftaPluginIS sdk initialization succeeded")
            
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

