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

+ (void)OnExternalMediationRequestWithBanner:(LPMBannerAdView * _Nonnull)banner adUnitId:(NSString * _Nonnull)adUnitId insight:(AdInsight * _Nullable)adInsight;
+ (void)OnExternalMediationRequestWithInterstitial:(LPMInterstitialAd * _Nonnull)interstitial adUnitId:(NSString * _Nonnull)adUnitId insight:(AdInsight * _Nullable)adInsight;
+ (void)OnExternalMediationRequestWithRewarded:(LPMRewardedAd * _Nonnull)rewarded adUnitId:(NSString * _Nonnull)adUnitId insight:(AdInsight * _Nullable)adInsight;

+ (void)OnExternalMediationRequestLoad:(LPMAdInfo * _Nonnull)adInfo;
+ (void)OnExternalMediationRequestFail:(NSError * _Nonnull)error;

+ (void)OnExternalMediationImpression:(LPMImpressionData * _Nonnull)impressionData;
+ (void)OnExternalMediationClick:(LPMAdInfo * _Nonnull)adInfo;

+ (NeftaPlugin * _Nonnull)initWithAppId:(NSString *_Nonnull)appId;
+ (NeftaPlugin * _Nonnull)initWithAppId:(NSString *_Nonnull)appId sendImpressions:(BOOL)sendImpressions;

+ (ISAdapterErrorType)NLoadToAdapterError:(NError *_Nonnull)error;
@end

@interface ISNeftaImpressionCollector : NSObject <LPMImpressionDataDelegate>
- (void)impressionDataDidSucceed:(LPMImpressionData *_Nonnull)impressionData;
@end

#endif /* ISNeftaCustomAdapter_h */
