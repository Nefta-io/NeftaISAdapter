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
    
    @IBOutlet weak var _demandControl: UISegmentedControl!
    @IBOutlet weak var _testSuite: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DebugServer.Init(viewController: self)
        
        NeftaPlugin.EnableLogging(enable: true)
        let plugin = ISNeftaCustomAdapter.initWithAppId("5759667955302400")
        plugin.OnReady = { initConfig in
            print("[NeftaPluginIS] Should bypass Nefta optimization? \(initConfig._skipOptimization)")
        }
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

