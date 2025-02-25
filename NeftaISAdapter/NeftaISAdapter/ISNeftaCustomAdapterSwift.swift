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
    
    static func OnExternalAdLoad(_ adType: AdTypeSwift, calculatedFloorPrice: Float64) {
        NeftaPlugin.OnExternalAdLoad("is", adType: adType.rawValue, unitFloorPrice: -1, calculatedFloorPrice: calculatedFloorPrice, status: 1)
    }
    
    static func OnExternalAdFail(_ adType: AdTypeSwift, calculatedFloorPrice: Float64, error: NSError?) {
        var status = 0
        if let e = error, e.code == ISErrorCode.ERROR_CODE_NO_ADS_TO_SHOW.rawValue ||
            e.code == ISErrorCode.ERROR_BN_LOAD_NO_FILL.rawValue ||
            e.code == ISErrorCode.ERROR_IS_LOAD_NO_FILL.rawValue ||
            e.code == ISErrorCode.ERROR_NT_LOAD_NO_FILL.rawValue ||
            e.code == ISErrorCode.ERROR_RV_LOAD_NO_FILL.rawValue {
            status = 2
        }
        NeftaPlugin.OnExternalAdLoad("is", adType: adType.rawValue, unitFloorPrice: -1, calculatedFloorPrice: calculatedFloorPrice, status: status)
    }
}
