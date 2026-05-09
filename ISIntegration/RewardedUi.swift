//
//  RewardedUi.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 9. 5. 26.
//  Copyright © 2026 ironsrc. All rights reserved.
//

class RewardedUi : UIView {
    public static let AdUnitA = "p3dh8r1mm3ua8fvv"
    public static let AdUnitB = "doucurq8qtlnuz7p"
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    
    private var _logic : Rewarded!
    
    public var IsAutoLoad: Bool = false
    public var ViewController: ViewController!
    
    public func Init(logic: Rewarded, viewController: ViewController) {
        _logic = logic
        _logic.Init(ui: self)
        
        ViewController = viewController
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        isHidden = false
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        IsAutoLoad = sender.isOn
        if IsAutoLoad {
            _logic.Load()
        }
    }
    
    public func SetAvailable(available: Bool) {
        _showButton.isEnabled = available
    }
    
    @objc private func OnShowClick() {
        _logic.Show()
    }
    
    public func Log(_ log: String) {
        _status.text = log
        ViewController._log.notice("Rewarded: \(log, privacy: .public)")
    }
}
