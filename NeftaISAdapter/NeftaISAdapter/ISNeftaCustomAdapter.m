//
//  ISNeftaCustomAdapter.m
//  Unity-iPhone
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import "ISNeftaCustomAdapter.h"

@implementation ISNeftaCustomAdapter

+(void) OnExternalMediationRequestLoad:(AdType)adType requestedFloorPrice:(double)requestedFloorPrice calculatedFloorPrice:(double)calculatedFloorPrice ad:(LPMAdInfo *)ad {
    [NeftaPlugin OnExternalMediationRequest: @"is" adType: adType requestedFloorPrice: requestedFloorPrice calculatedFloorPrice: calculatedFloorPrice adUnitId: ad.adUnitId revenue: ad.revenue.doubleValue precision: ad.precision status: 1];
}

+(void) OnExternalMediationRequestFail:(AdType)adType requestedFloorPrice:(double)requestedFloorPrice calculatedFloorPrice:(double)calculatedFloorPrice adUnitId:(NSString *)adUnitId error:(NSError *)error {
    int status = 0;
    if (error.code == ERROR_CODE_NO_ADS_TO_SHOW ||
        error.code == ERROR_BN_LOAD_NO_FILL ||
        error.code == ERROR_IS_LOAD_NO_FILL ||
        error.code == ERROR_NT_LOAD_NO_FILL ||
        error.code == ERROR_RV_LOAD_NO_FILL) {
        status = 2;
    }
    [NeftaPlugin OnExternalMediationRequest: @"is" adType: adType requestedFloorPrice: requestedFloorPrice calculatedFloorPrice: calculatedFloorPrice adUnitId: adUnitId revenue: -1 precision: nil status: status];
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
    return @"2.2.0";
}
@end

@implementation ISNeftaImpressionCollector
- (void)impressionDataDidSucceed:(ISImpressionData *)impressionData {
    if (impressionData.all_data == nil) {
        return;
    }
    NSMutableDictionary *data = impressionData.all_data.mutableCopy;
    [data setObject: @"ironsource_levelplay" forKey: @"mediation_provider"];
    [NeftaPlugin OnExternalMediationImpression: @"is" data: data];
}
@end
