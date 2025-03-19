//
//  ISNeftaCustomAdapter.h
//  UnityFramework
//
//  Created by Tomaz Treven on 14/11/2023.
//

#ifndef ISNeftaCustomAdapter_h
#define ISNeftaCustomAdapter_h

#import <Foundation/Foundation.h>
#import <IronSource/IronSource.h>
#import <NeftaSDK/NeftaSDK-Swift.h>

@interface ISNeftaCustomAdapter : ISBaseNetworkAdapter
typedef NS_ENUM(NSInteger, AdType) {
    AdTypeOther = 0,
    AdTypeBanner = 1,
    AdTypeInterstitial = 2,
    AdTypeRewarded = 3
};
+ (void)OnExternalMediationRequestLoad:(AdType)adType requestedFloorPrice:(double)requestedFloorPrice calculatedFloorPrice:(double)calculatedFloorPrice ad:(LPMAdInfo * _Nonnull)ad;
+ (void)OnExternalMediationRequestFail:(AdType)adType requestedFloorPrice:(double)requestedFloorPrice calculatedFloorPrice:(double)calculatedFloorPrice adUnitId:(NSString * _Nonnull)adUnitId error:(NSError * _Nonnull)error;
+ (NeftaPlugin*_Nonnull)initWithAppId:(NSString *_Nonnull)appId;
+ (NeftaPlugin*_Nonnull)initWithAppId:(NSString *_Nonnull)appId sendImpressions:(BOOL)sendImpressions;
@end

@interface ISNeftaImpressionCollector : NSObject <ISImpressionDataDelegate>
- (void)impressionDataDidSucceed:(ISImpressionData *_Nonnull)impressionData;
@end

#endif /* ISNeftaCustomAdapter_h */
