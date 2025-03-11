//
//  ISNeftaCustomAdapter.m
//  Unity-iPhone
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import "ISNeftaCustomAdapter.h"

@implementation ISNeftaCustomAdapter

+(void) OnExternalAdLoad:(AdType)adType calculatedFloorPrice:(double)calculatedFloorPrice {
    [NeftaPlugin OnExternalAdLoad: @"is" adType: adType unitFloorPrice: -1 calculatedFloorPrice: calculatedFloorPrice status: 1];
}

+(void) OnExternalAdFail:(AdType)adType calculatedFloorPrice:(double)calculatedFloorPrice error:(NSError *)error {
    int status = 0;
    if (error.code == ERROR_CODE_NO_ADS_TO_SHOW ||
        error.code == ERROR_BN_LOAD_NO_FILL ||
        error.code == ERROR_IS_LOAD_NO_FILL ||
        error.code == ERROR_NT_LOAD_NO_FILL ||
        error.code == ERROR_RV_LOAD_NO_FILL) {
        status = 2;
    }
    [NeftaPlugin OnExternalAdLoad: @"is" adType: adType unitFloorPrice: -1 calculatedFloorPrice: calculatedFloorPrice status: status];
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
    return @"2.1.2";
}
@end

@implementation ISNeftaImpressionCollector
- (void)impressionDataDidSucceed:(ISImpressionData *)impressionData {
    if (impressionData.all_data == nil) {
        return;
    }
    NSMutableDictionary *data = impressionData.all_data.mutableCopy;
    [data setObject: @"ironsource_levelplay" forKey: @"mediation_provider"];
    [NeftaPlugin OnExternalAdShown: @"is" data: data];
}
@end
