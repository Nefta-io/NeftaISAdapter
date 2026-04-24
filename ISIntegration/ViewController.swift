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

    public static var _log = Logger(subsystem: "com.nefta.is", category: "general")
    
    private var _isSimulator = false
    
    @IBOutlet weak var _titleLabel: UILabel!
    @IBOutlet weak var _demandControl: UISegmentedControl!
    @IBOutlet weak var _testSuite: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        InitializeUI()
        //DebugServer.Init(viewController: self)
        
        NeftaPlugin.EnableLogging(enable: true)
        ISNeftaCustomAdapter.Init(appId: "5759667955302400", sendImpressions: true, onReady: { initConfig in
            print("[NeftaPluginIS] Should skip Nefta optimization: \(initConfig._skipOptimization) for \(initConfig._nuid)")
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
                
                //_testSuite.addTarget(self, action: #selector(onTestSuite), for: .touchUpInside)
            }
        }
    }
    
    @objc func onTestSuite() {
        LevelPlay.launchTestSuite(self)
    }
    
    private func InitializeUI() {
        _titleLabel!.text = "Nefta Adapter for\n LevelPlay \(LevelPlay.sdkVersion())"
        let onClickHandler = UITapGestureRecognizer(target: self, action: #selector(onTitleClick))
        _titleLabel!.isUserInteractionEnabled = true
        _titleLabel!.addGestureRecognizer(onClickHandler)
        
        var isSimulator: Bool = false
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) {
            isSimulator = dict["IS_SIMULATOR"] as? Bool ?? false
        }
        ToggleUI(isSimulator: isSimulator)
    }
    
    @objc func onTitleClick() {
        ToggleUI(isSimulator: !_isSimulator)
    }
    
    private func ToggleUI(isSimulator: Bool) {
        _isSimulator = isSimulator
        
        (view.viewWithTag(11) as! InterstitialSim).isHidden = !isSimulator
        (view.viewWithTag(12) as! RewardedSim).isHidden = !isSimulator
        
        (view.viewWithTag(13) as! Interstitial).isHidden = isSimulator
        (view.viewWithTag(14) as! Rewarded).isHidden = isSimulator
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

