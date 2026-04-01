//
//  ISNeftaCustomAdapter.m
//  Unity-iPhone
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import "ISNeftaCustomAdapter.h"

#import <os/log.h>

NSString * const _mediationProvider = @"ironsource-levelplay";

@implementation ISNeftaCustomAdapter

+ (double) GetRetryDelayInSeconds:(AdInsight * _Nullable)insight {
    return (double)[NeftaPlugin GetRetryDelayInSeconds: insight];
}

+ (void)OnExternalMediationRequestWithBanner:(LPMBannerAdView * _Nonnull)banner adUnitId:(NSString *)adUnitId insight:(AdInsight * _Nullable)insight {
    [ISNeftaCustomAdapter OnExternalMediationRequest: AdTypeBanner id: banner.adId requestedAdUnitId: adUnitId insight: insight];
}
+ (void)OnExternalMediationRequestWithInterstitial:(LPMInterstitialAd * _Nonnull)interstitial adUnitId:(NSString *)adUnitId insight:(AdInsight * _Nullable)insight {
    [ISNeftaCustomAdapter OnExternalMediationRequest: AdTypeInterstitial id: interstitial.adId requestedAdUnitId: adUnitId insight: insight];
}
+ (void)OnExternalMediationRequestWithRewarded:(LPMRewardedAd * _Nonnull)rewarded adUnitId:(NSString *)adUnitId insight:(AdInsight * _Nullable)insight {
    [ISNeftaCustomAdapter OnExternalMediationRequest: AdTypeRewarded id: rewarded.adId requestedAdUnitId: adUnitId insight: insight];
}
+ (void)OnExternalMediationRequest:(AdType)adType id:(NSString * _Nonnull)id requestedAdUnitId:(NSString * _Nonnull)requestedAdUnitId insight:(AdInsight * _Nullable)insight {
    int requestId = -1;
    double requestedFloor = -1;
    if (insight != nil) {
        requestId = (int)insight._requestId;
        requestedFloor = insight._floorPrice;
    }
    [NeftaPlugin OnExternalMediationRequest: _mediationProvider adType: (int)adType id: id requestedAdUnitId: requestedAdUnitId requestedFloorPrice: requestedFloor requestId: requestId];
}

+ (void) OnExternalMediationRequestLoad:(LPMAdInfo * _Nonnull)adInfo {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject: adInfo.adNetwork forKey: @"adNetwork"];
    [NeftaPlugin OnExternalMediationResponse: _mediationProvider id: adInfo.adId id2: adInfo.auctionId revenue: adInfo.revenue.doubleValue precision: adInfo.precision status: 1 providerStatus: nil networkStatus: nil baseObject: data];
}

+ (void) OnExternalMediationRequestFail:(NSError * _Nonnull)error {
    int status = 0;
    if (error.code == ERROR_CODE_NO_ADS_TO_SHOW ||
        error.code == ERROR_BN_LOAD_NO_FILL ||
        error.code == ERROR_IS_LOAD_NO_FILL ||
        error.code == ERROR_NT_LOAD_NO_FILL ||
        error.code == ERROR_RV_LOAD_NO_FILL) {
        status = 2;
    }
    NSString *providerStatus = [NSString stringWithFormat:@"%ld", error.code];
    NSString *adId = error.userInfo != nil ? error.userInfo[@"adId"] : @"";
    [NeftaPlugin OnExternalMediationResponse: _mediationProvider id: adId id2: nil revenue: -1 precision: nil status: status providerStatus: providerStatus networkStatus: nil baseObject: nil];
}

+ (void)OnExternalMediationImpression:(LPMImpressionData * _Nonnull)impressionData {
    NSMutableDictionary *data = nil;
    if (impressionData.allData != nil) {
        data = impressionData.allData.mutableCopy;
    }
    NSString *id2 = impressionData.auctionId;
    [NeftaPlugin OnExternalMediationImpression: false provider: _mediationProvider data: data id: nil id2: id2];
}

+ (void)OnExternalMediationClick:(LPMAdInfo * _Nonnull)adInfo {
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    if (adInfo.adFormat != nil) {
        [data setObject: adInfo.adFormat forKey: @"adFormat"];
    }
    if (adInfo.adFormat != nil) {
        [data setObject: adInfo.adNetwork forKey: @"adNetwork"];
    }
    if (adInfo.revenue != nil) {
        [data setObject: adInfo.revenue forKey: @"revenue"];
    }
    if (adInfo.precision != nil) {
        [data setObject: adInfo.precision forKey: @"precision"];
    }
    if (adInfo.adUnitId != nil) {
        [data setObject: adInfo.adUnitId forKey: @"mediationAdUnitId"];
    }
  
    [NeftaPlugin OnExternalMediationImpression: true provider: _mediationProvider data: data id: adInfo.adId id2: nil];
}

static NeftaPlugin *_plugin;
static ISNeftaImpressionCollector *_impressionCollector;

+ (NeftaPlugin*)InitWithAppId:(NSString *)appId sendImpressions:(BOOL)sendImpressions onReady:(void (^_Nullable)(InitConfiguration *_Nonnull))onReady {
    _plugin = [NeftaPlugin NativeInitWithAppId: appId clientId: nil onReady: onReady integration: @"native-ironsource-levelplay" mediationVersion: LevelPlay.sdkVersion];
    if (sendImpressions) {
        _impressionCollector = [[ISNeftaImpressionCollector alloc] init];
        [LevelPlay addImpressionDataDelegate: _impressionCollector];
    }
    return _plugin;
}

+ (NeftaPlugin*)InitWithClientId:(NSString *)clientId sendImpressions:(BOOL)sendImpressions onReady:(void (^_Nullable)(InitConfiguration *_Nonnull))onReady {
    _plugin = [NeftaPlugin NativeInitWithAppId: nil clientId: clientId onReady: onReady integration: @"native-ironsource-levelplay" mediationVersion: LevelPlay.sdkVersion];
    if (sendImpressions) {
        _impressionCollector = [[ISNeftaImpressionCollector alloc] init];
        [LevelPlay addImpressionDataDelegate: _impressionCollector];
    }
    return _plugin;
}

+ (NeftaPlugin*)UnityInit:(NSString *)appId clientId:(NSString *)clientId sendImpressions:(BOOL)sendImpressions onReadyAsString:(void (^_Nonnull)(NSString *_Nonnull))onReadyAsString {
    _plugin = [NeftaPlugin UnityInitWithAppId: appId clientId: clientId onReadyAsString: onReadyAsString integration: @"unity-ironsource-levelplay" mediationVersion: LevelPlay.sdkVersion];
    if (sendImpressions) {
        _impressionCollector = [[ISNeftaImpressionCollector alloc] init];
        [LevelPlay addImpressionDataDelegate: _impressionCollector];
    }
    return _plugin;
}
@end

@implementation ISNeftaImpressionCollector
- (void)impressionDataDidSucceed:(LPMImpressionData *)impressionData {
    [ISNeftaCustomAdapter OnExternalMediationImpression: impressionData];
}
@end
