//
//  InterstitialSim.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 24. 11. 25.
//  Copyright © 2025 ironsrc. All rights reserved.
//

public class InterstitialSim : UIView {
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
        case Shown
    }
    
    public class Track : NSObject, LPMInterstitialAdDelegate {
        private let _controller: InterstitialSim
        
        public let _adUnitId: String
        public var _interstitial: SimInterstitial?
        public var _state: State = State.Idle
        public var _insight: AdInsight? = nil
        public var _revenue: Float64 = -1
        
        public init(controller: InterstitialSim, adUnitId: String) {
            _controller = controller
            _adUnitId = adUnitId
        }
        
        public func didFailToLoadAd(withAdUnitId adUnitId: String, error: any Error) {
            let lpError = error as NSError
            ISNeftaCustomAdapter.onExternalMediationRequestFail(lpError)
            
            _controller.Log("Load failed \(adUnitId): \(error.localizedDescription)")
            
            _interstitial = nil
            OnLoadFail()
        }
        
        public func OnLoadFail() {
            retryLoad()
            
            _controller.OnTrackLoad(false)
        }
        
        public func didLoadAd(with adInfo: LPMAdInfo) {
            ISNeftaCustomAdapter.onExternalMediationRequestLoad(adInfo)
            
            _controller.Log("Loaded \(adInfo.adUnitId) at: \(adInfo.revenue.doubleValue)")
            
            _insight = nil
            _revenue = adInfo.revenue.doubleValue
            _state = .Ready
            
            _controller.OnTrackLoad(true)
        }
        
        public func didClickAd(with adInfo: LPMAdInfo) {
            _controller.Log("didClick \(adInfo.adNetwork)")
            
            ISNeftaCustomAdapter.onExternalMediationClick(adInfo)
        }
        
        public func didChangeAdInfo(_ adInfo: LPMAdInfo) {
            _controller.Log("didChangeAdInfo \(adInfo.adNetwork)")
        }
        
        public func didFailToDisplayAd(withAdUnitId adUnitId: String, error: any Error) {
            _controller.Log("didFailToDisplayAd \(adUnitId): \(error.localizedDescription)")
            
            _state = .Idle
            _controller.RetryLoading()
        }
        
        public func didDisplayAd(with adInfo: LPMAdInfo) {
            _controller.Log("didOpen \(adInfo.adNetwork)")
        }
        
        public func didCloseAd(with adInfo: LPMAdInfo) {
            _controller.Log("didCloseAd \(adInfo.adNetwork)")
            
            _state = .Idle
            _controller.RetryLoading()
        }
        
        func retryLoad() {
            DispatchQueue.main.asyncAfter(deadline: .now() + ISNeftaCustomAdapter.GetRetryDelayInSeconds(insight: _insight)) {
                self._state = .Idle
                self._controller.RetryLoading()
            }
        }
    }
    
    private var _viewController: ViewController!
    private var _trackA: Track!
    private var _trackB: Track!
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

    public static var Instance: InterstitialSim!
    
    private func LoadTracks() {
        LoadTrack(track: _trackA, otherState: _trackB._state)
        LoadTrack(track: _trackB, otherState: _trackA._state)
    }
    
    private func LoadTrack(track: Track, otherState: State) {
        if track._state == .Idle {
            if otherState == .LoadingWithInsights || otherState == .Shown {
                if (_isFirstResponseReceived) {
                    LoadDefault(track: track)
                }
            } else {
                GetInsightsAndLoad(track: track)
            }
        }
    }
    
    private func GetInsightsAndLoad(track: Track) {
        track._state = .LoadingWithInsights
        
        NeftaPlugin._instance!.GetInsights(Insights.Interstitial, previousInsight: track._insight, callback: { insights in
            self.Log("Load with insights: \(insights)")
            if let insight = insights._interstitial {
                track._insight = insight
                let config = LPMInterstitialAdConfigBuilder()
                    .set(bidFloor: insight._floorPrice as NSNumber)
                    .build()
                track._interstitial = SimInterstitial(adUnitId: track._adUnitId, config: config)
                track._interstitial!.setDelegate(track)
                
                ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: track._interstitial!, adUnitId: track._adUnitId, insight: insight)
                
                self.Log("Loading \(track._adUnitId) as Optimized with floor: \(insight._floorPrice)")
                track._interstitial!.loadAd()
            } else {
                track.OnLoadFail()
            }
        })
    }
    
    private func LoadDefault(track: Track) {
        track._state = .Loading
        
        Log("Loading \(track._adUnitId) as Default")
        
        track._interstitial = SimInterstitial(adUnitId: track._adUnitId)
        track._interstitial!.setDelegate(track)
        
        ISNeftaCustomAdapter.onExternalMediationRequest(withInterstitial: track._interstitial!, adUnitId: track._adUnitId, insight: nil)

        track._interstitial!.loadAd()
    }
    
    func Init(viewController: ViewController) {
        _viewController = viewController
        InterstitialSim.Instance = self
        
        _trackA = Track(controller: self, adUnitId: InterstitialSim.AdUnitA)
        _trackB = Track(controller: self, adUnitId: InterstitialSim.AdUnitB)
        
        ToggleTrackA(isOn: false)
        _aFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackA, isHigh: true)
        }, for: .touchUpInside)
        _aFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackA, isHigh: false)
        }, for: .touchUpInside)
        _aNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackA, status: 2)
        }, for: .touchUpInside)
        _aOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackA, status: 0)
        }, for: .touchUpInside)
        
        ToggleTrackB(isOn: false)
        _bFill2.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackB, isHigh: true)
        }, for: .touchUpInside)
        _bFill1.addAction(UIAction { _ in
            self.SimOnAdLoadedEvent(request: self._trackB, isHigh: false)
        }, for: .touchUpInside)
        _bNoFill.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackB, status: 2)
        }, for: .touchUpInside)
        _bOther.addAction(UIAction { _ in
            self.SimOnAdFailedEvent(request: self._trackB, status: 0)
        }, for: .touchUpInside)
        
        _loadSwitch.addTarget(self, action: #selector(OnLoadSwitch), for: .valueChanged)
        _showButton.addTarget(self, action: #selector(OnShowClick), for: .touchUpInside)
        
        _showButton.isEnabled = false
        isHidden = false
    }
    
    @objc private func OnLoadSwitch(_ sender: UISwitch) {
        if sender.isOn {
            LoadTracks()
        }
    }
    
    @objc private func OnShowClick() {
        var isShown = false
        if _trackA._state == .Ready {
            if _trackB._state == .Ready && _trackB._revenue > _trackA._revenue {
                isShown = TryShow(adRequest: _trackB)
            }
            if !isShown {
                isShown = TryShow(adRequest: _trackA)
            }
        }
        if !isShown && _trackB._state == .Ready {
            isShown = TryShow(adRequest: _trackB)
        }
        
        UpdateShowButton()
    }
    
    private func TryShow(adRequest: Track) -> Bool {
        adRequest._revenue = -1
        if adRequest._interstitial!.isAdReady() {
            adRequest._state = .Shown
            adRequest._interstitial!.showAd(viewController: _viewController, placementName: nil)
            return true
        }
        adRequest._state = .Idle
        RetryLoading()
        return false
    }
    
    private func RetryLoading() {
        if _loadSwitch.isOn {
            LoadTracks()
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
        _showButton.isEnabled = _trackA._state == .Ready || _trackB._state == .Ready
    }
    
    private func Log(_ log: String) {
        _status.text = log
        _viewController._log.info("NeftaPluginMAX Simulator: \(log, privacy: .public)")
    }
    
    public class SimInterstitial : LPMInterstitialAd {
        public let _adUnitId: String
        public var _adInfo: LPMAdInfo?
        public var _floor: Double = -1.0
        public var _delegate: LPMInterstitialAdDelegate?
        
        public override init(adUnitId: String) {
            _adUnitId = adUnitId
            super.init(adUnitId: adUnitId)
        }
        
        public override init(adUnitId: String, config: LPMInterstitialAdConfig) {
            _adUnitId = adUnitId
            
            if let bidFloor = config.bidFloor {
                _floor = bidFloor.doubleValue
            }
            
            super.init(adUnitId: adUnitId, config: config)
        }
        
        public override func setDelegate(_ delegate: any LPMInterstitialAdDelegate) {
            _delegate = delegate
        }
        
        public override func loadAd() {
            let status = "\(_adUnitId) loading \(_floor >= 0 ? "as Optimized" : "as Default")"
            
            if _adUnitId == InterstitialSim.AdUnitA {
                InterstitialSim.Instance.ToggleTrackA(isOn: true)
                InterstitialSim.Instance.SetStatusA(status)
            } else {
                InterstitialSim.Instance.ToggleTrackB(isOn: true)
                InterstitialSim.Instance.SetStatusB(status)
            }
        }
        
        public override func showAd(viewController: UIViewController, placementName: String?) {
            
            ISNeftaCustomAdapter.onExternalMediationImpression((self._adInfo as! SLPMAdInfo).GetImpression())
            
            NDebug.Open(
                title: "Interstitial",
                viewController: viewController,
                onShow: { self._delegate!.didDisplayAd(with: self._adInfo!) },
                onClick: { self._delegate!.didClickAd?(with: self._adInfo!) },
                onClose: {
                    self._delegate!.didCloseAd?(with: self._adInfo!)
                    self._adInfo = nil
                },
                onReward: nil
            )
            
            if _adUnitId == InterstitialSim.AdUnitA {
                InterstitialSim.Instance.SetStatusA("Showing A")
            } else {
                InterstitialSim.Instance.SetStatusB("Showing B")
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
    
    func SimOnAdLoadedEvent(request: Track, isHigh: Bool) {
        let revenue = isHigh ? 0.002 : 0.001
        if request._interstitial!._adInfo != nil {
            request._interstitial!._adInfo = nil
            
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
        
        let adInfo = SLPMAdInfo(adId: request._interstitial!.adId, adUnitId: request._adUnitId, adFormat: "interstitial", revenue: revenue, precision: "BID")
        
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
        
        request._interstitial!.SimLoad(adInfo: adInfo)
    }
    
    func SimOnAdFailedEvent(request: Track, status: Int) {
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
        let error = NSError(domain: "com.nefta.is", code: Int(errorCode.rawValue), userInfo: ["adId": request._interstitial!.adId])
        request._interstitial!.SimFailLoad(error: error)
    }
    
    public func SetStatusA(_ status: String) {
        _aStatus.text = status
    }
    
    public func SetStatusB(_ status: String) {
        _bStatus.text = status
    }
}
