//
//  ISNeftaCustomAdapter.m
//  Unity-iPhone
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import "ISNeftaCustomAdapter.h"
#import "ISNeftaCustomBanner.h"
#import "ISNeftaCustomInterstitial.h"
#import "ISNeftaCustomRewardedVideo.h"

#import <os/log.h>

NSString * const _mediationProvider = @"ironsource-levelplay";

@implementation ISNeftaCustomAdapter

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
    int adOpportunityId = -1;
    double requestedFloor = -1;
    if (insight != nil) {
        adOpportunityId = (int)insight._adOpportunityId;
        requestedFloor = insight._floorPrice;
    }
    [NeftaPlugin OnExternalMediationRequest: _mediationProvider adType: (int)adType id: id requestedAdUnitId: requestedAdUnitId requestedFloorPrice: requestedFloor adOpportunityId: adOpportunityId];
}

+ (void) OnExternalMediationRequestLoad:(LPMAdInfo * _Nonnull)adInfo {
    [NeftaPlugin OnExternalMediationResponse: _mediationProvider id: adInfo.adId id2: adInfo.auctionId revenue: adInfo.revenue.doubleValue precision: adInfo.precision status: 1 providerStatus: nil networkStatus: nil];
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
    [NeftaPlugin OnExternalMediationResponse: _mediationProvider id: adId id2: nil revenue: -1 precision: nil status: status providerStatus: providerStatus networkStatus: nil];
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
static dispatch_semaphore_t _semaphore;

+ (NeftaPlugin*)initWithAppId:(NSString *)appId {
    return [ISNeftaCustomAdapter initWithAppId: appId sendImpressions: TRUE];
}

+ (NeftaPlugin*)initWithAppId:(NSString *)appId sendImpressions:(BOOL) sendImpressions {
    _plugin = [NeftaPlugin InitWithAppId: appId];
    if (sendImpressions) {
        _impressionCollector = [[ISNeftaImpressionCollector alloc] init];
        [LevelPlay addImpressionDataDelegate: _impressionCollector];
    }
    return _plugin;
}

- (void)setAdapterDebug:(BOOL)adapterDebug {
    //[NeftaPlugin EnableLogging: adapterDebug];
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    @synchronized (NeftaPlugin.Version) {
        if (_semaphore == nil) {
            _semaphore = dispatch_semaphore_create(1);
        }
        
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        if (_plugin != nil) {
            dispatch_semaphore_signal(_semaphore);
            [delegate onInitDidSucceed];
            return;
        }
        
        NSString *appId = [adData getString: @"appId"];
        if (appId == nil || appId.length == 0) {
            dispatch_semaphore_signal(_semaphore);
            [delegate onInitDidFailWithErrorCode:ISAdapterErrorMissingParams errorMessage:@"Missing appId"];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _plugin = [NeftaPlugin InitWithAppId: appId];
            
            dispatch_semaphore_signal(_semaphore);
            [delegate onInitDidSucceed];
        });
    }
}

- (NSString *) networkSDKVersion {
    return NeftaPlugin.Version;
}

- (NSString *) adapterVersion {
    return @"4.4.2";
}

+ (ISAdapterErrorType) NLoadToAdapterError:(NError *)error {
    if (error._code == CodeNoFill) {
        return ISAdapterErrorTypeNoFill;
    }
    if (error._code == CodeExpired) {
        return ISAdapterErrorTypeAdExpired;
    }
    return ISAdapterErrorTypeInternal;
}
@end

@implementation ISNeftaImpressionCollector
- (void)impressionDataDidSucceed:(LPMImpressionData *)impressionData {
    [ISNeftaCustomAdapter OnExternalMediationImpression: impressionData];
}
@end
