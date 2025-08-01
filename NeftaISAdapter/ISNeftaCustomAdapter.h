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
+ (void)OnExternalMediationRequestLoad:(AdType)adType usedInsight:(AdInsight * _Nullable)usedInsight requestedFloorPrice:(double)requestedFloorPrice adInfo:(LPMAdInfo * _Nonnull)adInfo;
+ (void)OnExternalMediationRequestFail:(AdType)adType usedInsight:(AdInsight * _Nullable)usedInsight requestedFloorPrice:(double)requestedFloorPrice adUnitId:(NSString * _Nonnull)adUnitId error:(NSError * _Nonnull)error;
+ (NeftaPlugin*_Nonnull)initWithAppId:(NSString *_Nonnull)appId;
+ (NeftaPlugin*_Nonnull)initWithAppId:(NSString *_Nonnull)appId sendImpressions:(BOOL)sendImpressions;

+ (ISAdapterErrorType)NLoadToAdapterError:(NError *_Nonnull)error;
@end

@interface ISNeftaImpressionCollector : NSObject <ISImpressionDataDelegate>
- (void)impressionDataDidSucceed:(ISImpressionData *_Nonnull)impressionData;
@end

#endif /* ISNeftaCustomAdapter_h */
