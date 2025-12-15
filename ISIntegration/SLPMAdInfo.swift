//
//  SLPMAdInfo.swift
//  ISIntegration
//
//  Created by Tomaz Treven on 25. 11. 25.
//  Copyright © 2025 ironsrc. All rights reserved.
//

public class SLPMAdInfo : LPMAdInfo {
    let _adId: String
    let _adUnitId: String
    let _adFormat: String
    let _revenue: NSNumber
    let _precision: String
    let _auctionId: String
    
    public init(adId: String, adUnitId: String, adFormat: String, revenue: Float64, precision: String) {
        _adId = adId
        _adUnitId = adUnitId
        _adFormat = adFormat
        _revenue = NSNumber(value: revenue)
        _precision = precision
        _auctionId = "\(_adId)_auction"
    }
    
    public override var adId: String {
        return _adId
    }
    
    public override var adUnitId: String {
        return _adUnitId
    }
    
    public override var adFormat: String {
        return _adFormat
    }
    
    public override var revenue: NSNumber {
        return _revenue
    }
    
    public override var precision: String {
        return _precision
    }
    
    public override var auctionId: String {
        return _auctionId
    }
    
    public func GetImpression() -> SLPMImpressionData {
        return SLPMImpressionData(self)
    }
}

public class SLPMImpressionData : LPMImpressionData {
    let _auctionId: String
    let _mediationAdUnitId: String
    let _adFormat: String
    let _revenue: NSNumber
    let _precision: String
    
    init(_ adInfo: SLPMAdInfo) {
        _auctionId = adInfo._auctionId
        _mediationAdUnitId = adInfo._adUnitId
        _adFormat = adInfo.adFormat
        _revenue = adInfo.revenue
        _precision = adInfo.precision
        
        super.init()
    }
    
    public override var auctionId: String {
        return _auctionId
    }
    
    public override var mediationAdUnitId: String {
        return _mediationAdUnitId
    }
    
    public override var adFormat: String {
        return _adFormat
    }
    
    public override var revenue: NSNumber {
        return _revenue
    }
    
    public override var precision: String {
        return _precision
    }
    
    public override var allData: [AnyHashable : Any]? {
        return [
            "auctionId": _auctionId,
            "mediationAdUnitId": _mediationAdUnitId,
            "mediationAdUnitName": "",
            "adFormat": _adFormat,
            "adNetwork": "simulator",
            "instanceName": "",
            "instanceId": "",
            "country": "",
            "placement": "",
            "revenue": _revenue.doubleValue,
            "precision": _precision,
            "creativeId": "simulator creative \(_auctionId)",
        ]
    }
}
