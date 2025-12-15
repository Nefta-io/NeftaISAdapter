//
//  RewardedSim.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 24. 11. 25.
//  Copyright © 2025 ironsrc. All rights reserved.
//

public class RewardedSim : UIView {
    public static let AdUnitA = "Track A"
    public static let AdUnitB = "Track B"
    private let TimeoutInSeconds = 5
    private let DefaultBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    private let DefaultColor = UIColor(red: 0.6509804, green: 0.1490196, blue: 0.7490196, alpha: 1.0)
    private let FillColor = UIColor.green
    private let NoFillColor = UIColor.red
    
    public enum State {
        case Idle
        case LoadingWithInsights
        case Loading
        case Ready
    }
    
    public class AdRequest : NSObject, LPMRewardedAdDelegate {
        private var _controller: RewardedSim
        
        public let _adUnitId: String
        public var _rewarded: SimRewarded?
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        public var _consecutiveAdFails: Int = 0
        
        public init(controller: RewardedSim, adUnitId: String) {
            _controller = controller
            _adUnitId = adUnitId
        }
        
        public func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
            let lpError = error as NSError
            ISNeftaCustomAdapter.onExternalMediationRequestFail(lpError)
            
            _controller.Log("Load failed \(adUnitId): \(error.localizedDescription)")
            
            _rewarded = nil
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            _consecutiveAdFails += 1
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        public func didLoadAd(with adInfo: LPMAdInfo) {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
            
            _controller.Log("Loaded \(adInfo.adUnitId) at: \(adInfo.revenue.doubleValue)")
            
            _insight = nil
            _consecutiveAdFails = 0
            _revenue = adInfo.revenue.doubleValue
            _state = State.Ready
            
            _controller.OnTrackLoad(true)
        }
        
        public func didClickAd(with adInfo: LPMAdInfo) {
            _controller.Log("didClick \(adInfo.adNetwork)")
            
            ISNeftaCustomAdapter.onExternalMediationClick(adInfo)
        }
        
        public func didChangeAdInfo(_ adInfo: LPMAdInfo) {
            _controller.Log("didChangeAdInfo \(adInfo.adNetwork)")
        }
        
        public func didRewardAd(with adInfo: LPMAdInfo, reward: LPMReward) {
            _controller.Log("didRewardAd \(adInfo)")
        }
        
        public func didFailToDisplayAd(withAdUnitId adUnitId: String, error: any Error) {
            _controller.Log("didFailToDisplayAd \(adUnitId): \(error.localizedDescription)")
        }
        
        public func didDisplayAd(with adInfo: LPMAdInfo) {
            _controller.Log("didOpen \(adInfo.adNetwork)")
        }
        
        public func didCloseAd(with adInfo: LPMAdInfo) {
            _controller.Log("didCloseAd \(adInfo.adNetwork)")
            
            _controller.RetryLoading()
        }
        
        func retryLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self._state = State.Idle
                self._controller.RetryLoading()
            }
        }
    }
    
    private var _adRequestA: AdRequest!
    private var _adRequestB: AdRequest!
    private var _isFirstResponseReceived = false
    
    @IBOutlet weak var _loadSwitch: UISwitch!
    @IBOutlet weak var _showButton: UIButton!
    @IBOutlet weak var _status: UILabel!
    
    @IBOutlet weak var _aFill2: UIButton!
    @IBOutlet weak var _aFill1: UIButton!
    @IBOutlet weak var _aNoFill: UIButton!
    @IBOutlet weak var _aOther: UIButton!
    @IBOutlet weak var _aStatus: UILabel!
    
    @IBOutlet weak var _bFill2: UIButton!
    @IBOutlet weak var _bFill1: UIButton!
    @IBOutlet weak var _bNoFill: UIButton!
    @IBOutlet weak var _bOther: UIButton!
    @IBOutlet weak var _bStatus: UILabel!
    
    @IBOutlet weak var _simulatorAd: SimulatorAd!
    
    public static var Instance: RewardedSim!
    
    private func StartLoading() {
        Load(request: _adRequestA, otherState: _adRequestB._state)
        Load(request: _adRequestB, otherState: _adRequestA._state)
    }
    
    private func Load(request: AdRequest, otherState: State) {
        if request._state == State.Idle {
            if otherState != State.LoadingWithInsights {
                GetInsightsAndLoad(adRequest: request)
            } else if (_isFirstResponseReceived) {
                LoadDefault(adRequest: request)
            }
        }
    }
    
    private func GetInsightsAndLoad(adRequest: AdRequest) {
        adRequest._state = State.LoadingWithInsights
        
        NeftaPlugin._instance.GetInsights(Insights.Rewarded, previousInsight: adRequest._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._rewarded {
                adRequest._insight = insight
                let config = LPMRewardedAdConfigBuilder()
                    .set(bidFloor: insight._floorPrice as NSNumber)
                    .build()
                adRequest._rewarded = SimRewarded(adUnitId: adRequest._adUnitId, config: config)
                adRequest._rewarded!.setDelegate(adRequest)
                
                ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!, adUnitId: adRequest._adUnitId, insight: insight)
                
                self.Log("Loading \(adRequest._adUnitId) as Optimized with floor: \(insight._floorPrice)")
                adRequest._rewarded!.loadAd()
            } else {
                adRequest.OnLoadFail()
            }
        }, timeout: TimeoutInSeconds)
    }
    
    private func LoadDefault(adRequest: AdRequest) {
        adRequest._state = State.Loading
        
        Log("Loading \(adRequest._adUnitId) as Default")
        
        adRequest._rewarded = SimRewarded(adUnitId: adRequest._adUnitId)
        adRequest._rewarded!.setDelegate(adRequest)
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withRewarded: adRequest._rewarded!, adUnitId: adRequest._adUnitId, insight: nil)

        adRequest._rewarded!.loadAd()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        RewardedSim.Instance = self
        
        _adRequestA = AdRequest(controller: self, adUnitId: InterstitialSim.AdUnitA)
        _adRequestB = AdRequest(controller: self, adUnitId: InterstitialSim.AdUnitB)
        
        ToggleTrackA(isOn: false)
        _aFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestA, isHigh: true)
        }, for: .touchUpInside)
        _aFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestA, isHigh: false)
        }, for: .touchUpInside)
        _aNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestA, status: 2)
        }, for: .touchUpInside)
        _aOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestA, status: 0)
        }, for: .touchUpInside)
        
        ToggleTrackB(isOn: false)
        _bFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestB, isHigh: true)
        }, for: .touchUpInside)
        _bFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._adRequestB, isHigh: false)
        }, for: .touchUpInside)
        _bNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestB, status: 2)
        }, for: .touchUpInside)
        _bOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._adRequestB, status: 0)
        }, for: .touchUpInside)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            StartLoading()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        if _adRequestA._state == State.Ready {
            if _adRequestB._state == State.Ready && _adRequestB._revenue > _adRequestA._revenue {
                isShown = TryShow(adRequest: _adRequestB)
            }
            if !isShown {
                isShown = TryShow(adRequest: _adRequestA)
            }
        }
        if !isShown && _adRequestB._state == State.Ready {
            isShown = TryShow(adRequest: _adRequestB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(adRequest: AdRequest) -> Bool {
        adRequest._state = State.Idle
        adRequest._revenue = -1

        if adRequest._rewarded!.isAdReady() {
            adRequest._rewarded!.showAd(viewController: GetViewController()!, placementName: nil)
            return true
        }
        RetryLoading()
        return false
    }
    
    private func RetryLoading() {
        if _loadSwitch.isOn {
            StartLoading()
        }
    }
    
    private func OnTrackLoad(_ success: Bool) {
        if success {
            UpdateShowButton()
        }
        
        _isFirstResponseReceived = true
        RetryLoading()
    }
    
    private func UpdateShowButton() {
        _showButton.isEnabled = _adRequestA._state == State.Ready || _adRequestB._state == State.Ready
    }
    
    private func OnHide() {
        if _loadSwitch.isOn {
            StartLoading()
        }
    }
    
    private func Log(_ log: String) {
        _status.text = log
        ViewController._log.info("NeftaPluginMAX Simulator: \(log, privacy: .public)")
    }
    
    public class SimRewarded : LPMRewardedAd {
        public let _adUnitId: String
        public var _adInfo: LPMAdInfo?
        public var _floor: Double = -1.0
        public var _delegate: LPMRewardedAdDelegate?
        
        public override init(adUnitId: String) {
            _adUnitId = adUnitId

            super.init(adUnitId: adUnitId)
        }
        
        public override init(adUnitId: String, config: LPMRewardedAdConfig) {
            _adUnitId = adUnitId
            
            if let bidFloor = config.bidFloor {
                _floor = bidFloor.doubleValue
            }
            
            super.init(adUnitId: adUnitId, config: config)
        }
        
        public override func setDelegate(_ delegate: any LPMRewardedAdDelegate) {
            _delegate = delegate
        }
        
        public override func loadAd() {
            let status = "\(_adUnitId) loading \(_floor >= 0 ? "as Optimized" : "as Default")"
            
            if _adUnitId == InterstitialSim.AdUnitA {
                RewardedSim.Instance.ToggleTrackA(isOn: true)
                RewardedSim.Instance.SetStatusA(status)
            } else {
                RewardedSim.Instance.ToggleTrackB(isOn: true)
                RewardedSim.Instance.SetStatusB(status)
            }
        }
        
        public override func showAd(viewController: UIViewController, placementName: String?) {
       
            ISNeftaCustomAdapter.onExternalMediationImpression((self._adInfo as! SLPMAdInfo).GetImpression())
            
            InterstitialSim.Instance.Show(title: "Rewarded",
                                          onShow: { self._delegate!.didDisplayAd(with: self._adInfo!) },
                                          onClick: { self._delegate!.didClickAd?(with: self._adInfo!) },
                                          onReward: { self._delegate!.didRewardAd(with: self._adInfo!, reward: LPMReward(name:"sim reward", amount: 1)) },
                                          onClose: {
                    self._delegate!.didCloseAd!(with: self._adInfo!)
                    self._adInfo = nil
                }
            )
            
            if _adUnitId == InterstitialSim.AdUnitA {
                RewardedSim.Instance.SetStatusA("Showing A")
            } else {
                RewardedSim.Instance.SetStatusB("Showing B")
            }
        }
        
        public func SimLoad(adInfo: LPMAdInfo) {
            _adInfo = adInfo
            _delegate!.didLoadAd(with: _adInfo!)
        }
        
        public func SimFailLoad(error: NSError) {
            _delegate!.didFailToLoadAd(withAdUnitId: _adUnitId, error: error)
        }
        
        public override func isAdReady() -> Bool {
            return _adInfo != nil
        }
    }
    
    private func ToggleTrackA(isOn: Bool) {
        _aFill2.isEnabled = isOn
        _aFill1.isEnabled = isOn
        _aNoFill.isEnabled = isOn
        _aOther.isEnabled = isOn
        
        if isOn {
            _aFill2.tintColor = DefaultColor
            _aFill2.backgroundColor = DefaultBackgroundColor
            _aFill1.tintColor = DefaultColor
            _aFill1.backgroundColor = DefaultBackgroundColor
            _aNoFill.tintColor = DefaultColor
            _aNoFill.backgroundColor = DefaultBackgroundColor
            _aOther.tintColor = DefaultColor
            _aOther.backgroundColor = DefaultBackgroundColor
        }
    }
    
    private func ToggleTrackB(isOn: Bool) {
        _bFill2.isEnabled = isOn
        _bFill1.isEnabled = isOn
        _bNoFill.isEnabled = isOn
        _bOther.isEnabled = isOn
        
        if isOn {
            _bFill2.tintColor = DefaultColor
            _bFill2.backgroundColor = DefaultBackgroundColor
            _bFill1.tintColor = DefaultColor
            _bFill1.backgroundColor = DefaultBackgroundColor
            _bNoFill.tintColor = DefaultColor
            _bNoFill.backgroundColor = DefaultBackgroundColor
            _bOther.tintColor = DefaultColor
            _bOther.backgroundColor = DefaultBackgroundColor
        }
    }
    
    func SimOnAdLoadedEvent(request: AdRequest, isHigh: Bool) {
        let revenue = isHigh ? 0.002 : 0.001
        if request._rewarded!._adInfo != nil {
            request._rewarded!._adInfo = nil
            
            if request._adUnitId == InterstitialSim.AdUnitA {
                if isHigh {
                    _aFill2.tintColor = DefaultColor
                    _aFill2.backgroundColor = DefaultColor
                    _aFill2.isEnabled = false
                } else{
                    _aFill1.tintColor = DefaultColor
                    _aFill1.backgroundColor = DefaultColor
                    _aFill1.isEnabled = false
                }
            } else {
                if isHigh {
                    _bFill2.tintColor = DefaultColor
                    _bFill2.backgroundColor = DefaultColor
                    _bFill2.isEnabled = false
                } else{
                    _bFill1.tintColor = DefaultColor
                    _bFill1.backgroundColor = DefaultColor
                    _bFill1.isEnabled = false
                }
            }
            return
        }
        
        let adInfo = SLPMAdInfo(adId: request._rewarded!.adId, adUnitId: request._adUnitId, adFormat: "rewarded_video", revenue: revenue, precision: "BID")
        
        if request._adUnitId == InterstitialSim.AdUnitA {
            ToggleTrackA(isOn: false)
            if isHigh {
                _aFill2.tintColor = FillColor
                _aFill2.backgroundColor = FillColor
                _aFill2.isEnabled = true
            } else {
                _aFill1.tintColor = FillColor
                _aFill1.backgroundColor = FillColor
                _aFill1.isEnabled = true
            }
            SetStatusA("\(request._adUnitId) loaded \(revenue)")
        } else {
            ToggleTrackB(isOn: false)
            if isHigh {
                _bFill2.tintColor = FillColor
                _bFill2.backgroundColor = FillColor
                _bFill2.isEnabled = true
            } else {
                _bFill1.tintColor = FillColor
                _bFill1.backgroundColor = FillColor
                _bFill1.isEnabled = true
            }
            SetStatusB("\(request._adUnitId) loaded \(revenue)")
        }
        
        request._rewarded!.SimLoad(adInfo: adInfo)
    }
    
    func SimOnAdFailedEvent(request: AdRequest, status: Int) {
        if request._adUnitId == InterstitialSim.AdUnitA {
            if status == 2 {
                _aNoFill.tintColor = NoFillColor
                _aNoFill.backgroundColor = NoFillColor
            } else {
                _aOther.tintColor = NoFillColor
                _aOther.backgroundColor = NoFillColor
            }
            ToggleTrackA(isOn: false)
            SetStatusA("\(request._adUnitId) failed")
        } else {
            if status == 2 {
                _bNoFill.tintColor = NoFillColor
                _bNoFill.backgroundColor = NoFillColor
            } else {
                _bOther.tintColor = NoFillColor
                _bOther.backgroundColor = NoFillColor
            }
            ToggleTrackB(isOn: false)
            SetStatusB("\(request._adUnitId) failed")
        }
        
        let errorCode = status == 2 ? ISErrorCode.ERROR_IS_LOAD_NO_FILL : ISErrorCode.ERROR_CODE_GENERIC
        let error = NSError(domain: "com.nefta.is", code: Int(errorCode.rawValue), userInfo: ["adId": request._rewarded!.adId])
        request._rewarded!.SimFailLoad(error: error)
    }
    
    public func SetStatusA(_ status: String) {
        _aStatus.text = status
    }
    
    public func SetStatusB(_ status: String) {
        _bStatus.text = status
    }
    
    public func Show(title: String, onShow: @escaping (() -> Void), onClick: @escaping (() -> Void), onReward: (() -> Void)!, onClose: @escaping (() -> Void)) {
        _simulatorAd.Show(title: title, onShow: onShow, onClick: onClick, onReward: onReward, onClose: onClose)
    }
    
    private func GetViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let vc = responder as? UIViewController {
                return vc
            }
        }
        return nil
    }
}
