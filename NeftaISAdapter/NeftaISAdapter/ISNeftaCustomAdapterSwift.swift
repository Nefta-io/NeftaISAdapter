//
//  ISNeftaCustomAdapterSwift.swift
//  ISAdapter
//
//  Created by Tomaz Treven on 24. 2. 25.
//

import NeftaSDK
import IronSource

class ISNeftaCustomAdapterSwift {
    enum AdTypeSwift : Int{
        case Other = 0
        case Banner = 1
        case Interstitial = 2
        case Rewarded = 3
    }
    
    static func OnExternalMediationRequestLoad(_ adType: AdTypeSwift, requestedFloorPrice: Float64, calculatedFloorPrice: Float64, adInfo: LPMAdInfo) {
        NeftaPlugin.OnExternalMediationRequest("is", adType: adType.rawValue, requestedFloorPrice: requestedFloorPrice, calculatedFloorPrice: calculatedFloorPrice, adUnitId: adInfo.adUnitId, revenue: adInfo.revenue.doubleValue, precision: adInfo.precision, status: 1)
    }
    
    static func OnExternalMediationRequestFail(_ adType: AdTypeSwift, requestedFloorPrice: Float64, calculatedFloorPrice: Float64, adUnitId: String, error: NSError?) {
        var status = 0
        if let e = error, e.code == ISErrorCode.ERROR_CODE_NO_ADS_TO_SHOW.rawValue ||
            e.code == ISErrorCode.ERROR_BN_LOAD_NO_FILL.rawValue ||
            e.code == ISErrorCode.ERROR_IS_LOAD_NO_FILL.rawValue ||
            e.code == ISErrorCode.ERROR_NT_LOAD_NO_FILL.rawValue ||
            e.code == ISErrorCode.ERROR_RV_LOAD_NO_FILL.rawValue {
            status = 2
        }
        NeftaPlugin.OnExternalMediationRequest("is", adType: adType.rawValue, requestedFloorPrice: requestedFloorPrice, calculatedFloorPrice: calculatedFloorPrice, adUnitId: adUnitId, revenue: -1, precision: nil, status: status)
    }
}
