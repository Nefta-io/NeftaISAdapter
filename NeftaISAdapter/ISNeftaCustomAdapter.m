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

+(void) OnExternalMediationRequestLoad:(AdType)adType usedInsight:(AdInsight * _Nullable)usedInsight requestedFloorPrice:(double)requestedFloorPrice adInfo:(LPMAdInfo *)adInfo {
    [ISNeftaCustomAdapter OnExternalMediationRequest: adType insight: usedInsight requestedFloorPrice: requestedFloorPrice adUnitId: adInfo.adUnitId revenue: adInfo.revenue.doubleValue precision: adInfo.precision status: 1 providerStatus: nil];
}

+(void) OnExternalMediationRequestFail:(AdType)adType usedInsight:(AdInsight * _Nullable)usedInsight requestedFloorPrice:(double)requestedFloorPrice adUnitId:(NSString * _Nonnull)adUnitId error:(NSError *)error {
    int status = 0;
    if (error.code == ERROR_CODE_NO_ADS_TO_SHOW ||
        error.code == ERROR_BN_LOAD_NO_FILL ||
        error.code == ERROR_IS_LOAD_NO_FILL ||
        error.code == ERROR_NT_LOAD_NO_FILL ||
        error.code == ERROR_RV_LOAD_NO_FILL) {
        status = 2;
    }
    NSString *providerStatus = [NSString stringWithFormat:@"%ld", error.code];
    [ISNeftaCustomAdapter OnExternalMediationRequest: adType insight:usedInsight requestedFloorPrice: requestedFloorPrice adUnitId: adUnitId revenue: -1 precision: nil status: status providerStatus: providerStatus];
}

+(void)OnExternalMediationRequest:(AdType) adType insight:(AdInsight * _Nullable)insight requestedFloorPrice:(double)requestedFloorPrice adUnitId:(NSString * _Nonnull)adUnitId revenue:(double)revenue precision:(NSString * _Nullable)precision status:(int)status providerStatus:(NSString * _Nullable)providerStatus {
    double calculatedFloorPrice = 0;
    if (insight != nil) {
        calculatedFloorPrice = insight._floorPrice;
        
        if ((int)adType != insight._type) {
            NSLog(@"OnExternalMediationRequest reported adType: %ld doesn't match insight adType: %ld", adType, insight._type);
        }
    }
    [NeftaPlugin OnExternalMediationRequest: _mediationProvider adType: (int)adType recommendedAdUnitId: nil requestedFloorPrice: requestedFloorPrice calculatedFloorPrice: calculatedFloorPrice adUnitId: adUnitId revenue: revenue precision: precision status: status providerStatus: providerStatus networkStatus: nil];
}

static NeftaPlugin *_plugin;
static ISNeftaImpressionCollector *_impressionCollector;
static dispatch_semaphore_t _semaphore;

+ (NeftaPlugin*)initWithAppId:(NSString *)appId {
    return [ISNeftaCustomAdapter initWithAppId: appId sendImpressions: TRUE];
}

+ (NeftaPlugin*)initWithAppId:(NSString *)appId sendImpressions:(BOOL) sendImpressions {
    _plugin = [NeftaPlugin InitWithAppId: appId];
    _impressionCollector = [[ISNeftaImpressionCollector alloc] init];
    [IronSource addImpressionDataDelegate: _impressionCollector];
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
    return @"4.3.2";
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
- (void)impressionDataDidSucceed:(ISImpressionData *)impressionData {
    if (impressionData.all_data == nil) {
        return;
    }
    NSMutableDictionary *data = impressionData.all_data.mutableCopy;
    int adType = 0;
    BOOL isNeftaNetwork = [impressionData.ad_network isEqualToString: @"nefta"];
    NSString* auctionId;
    NSString* creativeId;
    NSString* format = impressionData.ad_format;
    if (format != nil) {
        NSString* lowerFormat = [format lowercaseString];
        if ([lowerFormat isEqualToString: @"banner"]) {
            adType = AdTypeBanner;
            if (isNeftaNetwork) {
                auctionId = ISNeftaCustomBanner.GetLastAuctionId;
                creativeId = ISNeftaCustomBanner.GetLastCreativeId;
            }
        } else if ([lowerFormat rangeOfString: @"inter"].location != NSNotFound) {
            adType = AdTypeInterstitial;
            if (isNeftaNetwork) {
                auctionId = ISNeftaCustomInterstitial.GetLastAuctionId;
                creativeId = ISNeftaCustomInterstitial.GetLastCreativeId;
            }
        } else if ([lowerFormat rangeOfString: @"rewarded"].location != NSNotFound) {
            adType = AdTypeRewarded;
            if (isNeftaNetwork) {
                auctionId = ISNeftaCustomRewardedVideo.GetLastAuctionId;
                creativeId = ISNeftaCustomRewardedVideo.GetLastCreativeId;
            }
        }
        if (auctionId != nil) {
            [data setObject: auctionId forKey: @"ad_opportunity_id"];
        }
        if (creativeId != nil) {
            [data setObject: creativeId forKey: @"creative_id"];
        }
    }
    [NeftaPlugin OnExternalMediationImpression: _mediationProvider data: data adType: adType revenue: [impressionData.revenue doubleValue] precision: impressionData.precision];
}
@end
