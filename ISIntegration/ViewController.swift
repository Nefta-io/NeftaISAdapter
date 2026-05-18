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
import OSLog

class ViewController: UIViewController {

    public var _log = Logger(subsystem: "com.nefta.is", category: "general")
    
    @IBOutlet weak var _title: UILabel!
    @IBOutlet weak var _testSuite: UIButton!
    
    @IBOutlet weak var _groupView: UIView!
    @IBOutlet weak var _controlButton: UIButton!
    @IBOutlet weak var _optimizedButton: UIButton!
    @IBOutlet weak var _simulatorButton: UIButton!
    
    @IBOutlet weak var _interstitialUi: InterstitialUi!
    @IBOutlet weak var _rewardedUi: RewardedUi!
    @IBOutlet weak var _interstitialSim: InterstitialSim!
    @IBOutlet weak var _rewardedSim: RewardedSim!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        InitializeUI()
        //DebugServer.Init(viewController: self)
        
        NeftaPlugin.EnableLogging(enable: true)
        ISNeftaCustomAdapter.Init(appId: "5759667955302400", sendImpressions: true, onReady: { initConfig in
            print("Nefta initialized, nuid: \(initConfig._nuid)")
        })
        
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) {
            if let ironSourceKey = dict["IS_KEY"] as? String {
                LevelPlay.setMetaDataWithKey("is_test_suite", value: "enable")
                
                let requestBuilder = LPMInitRequestBuilder(appKey: ironSourceKey)
                let initRequest = requestBuilder.build()
                LevelPlay.initWith(initRequest)
                { config, error in
                    guard error == nil else {
                        print("NeftaPluginIS sdk initialization failed, error =\(error?.localizedDescription ?? "unknown error")")
                        return
                    }
                    print("NeftaPluginIS sdk initialization succeeded")
                }
                
                _testSuite.addTarget(self, action: #selector(onTestSuite), for: .touchUpInside)
            }
        }
    }
    
    @objc func onTestSuite() {
        LevelPlay.launchTestSuite(self)
    }
    
    private func InitializeUI() {
        _title!.text = "Nefta Adapter for\n LevelPlay \(LevelPlay.sdkVersion())"
        
        _controlButton.addTarget(self, action: #selector(OnControlClick), for: .touchUpInside)
        _optimizedButton.addTarget(self, action: #selector(OnOptimizedClick), for: .touchUpInside)
        _simulatorButton.addTarget(self, action: #selector(OnSimulatorClick), for: .touchUpInside)
    }
    
    @objc func OnControlClick() {
        _groupView.isHidden = true
        
        _interstitialUi.Init(logic: InterstitialDefault(), viewController: self)
        _rewardedUi.Init(logic: RewardedDefault(), viewController: self)
    }
    
    @objc func OnOptimizedClick() {
        _groupView.isHidden = true
        
        _interstitialUi.Init(logic: InterstitialOptimized(), viewController: self)
        _rewardedUi.Init(logic: RewardedOptimized(), viewController: self)
    }
    
    @objc func OnSimulatorClick() {
        _groupView.isHidden = true
        
        _interstitialSim.Init(viewController: self)
        _rewardedSim.Init(viewController: self)
    }
}

