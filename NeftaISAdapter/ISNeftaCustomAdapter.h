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

+ (double) GetRetryDelayInSeconds:(AdInsight * _Nullable)insight NS_SWIFT_NAME(GetRetryDelayInSeconds(insight:));

+ (void)OnExternalMediationRequestWithBanner:(LPMBannerAdView * _Nonnull)banner adUnitId:(NSString * _Nonnull)adUnitId insight:(AdInsight * _Nullable)adInsight;
+ (void)OnExternalMediationRequestWithInterstitial:(LPMInterstitialAd * _Nonnull)interstitial adUnitId:(NSString * _Nonnull)adUnitId insight:(AdInsight * _Nullable)adInsight;
+ (void)OnExternalMediationRequestWithRewarded:(LPMRewardedAd * _Nonnull)rewarded adUnitId:(NSString * _Nonnull)adUnitId insight:(AdInsight * _Nullable)adInsight;

+ (void)OnExternalMediationRequestLoad:(LPMAdInfo * _Nonnull)adInfo;
+ (void)OnExternalMediationRequestFail:(NSError * _Nonnull)error;

+ (void)OnExternalMediationImpression:(LPMImpressionData * _Nonnull)impressionData;
+ (void)OnExternalMediationClick:(LPMAdInfo * _Nonnull)adInfo;

+ (NeftaPlugin * _Nonnull)InitWithAppId:(NSString *_Nonnull)appId sendImpressions:(BOOL)sendImpressions onReady:(void (^_Nullable)(InitConfiguration *_Nonnull))onReady NS_SWIFT_NAME(Init(appId:sendImpressions:onReady:));
+ (NeftaPlugin * _Nonnull)InitWithClientId:(NSString *_Nonnull)clientId sendImpressions:(BOOL)sendImpressions onReady:(void (^_Nullable)(InitConfiguration *_Nonnull))onReady NS_SWIFT_NAME(Init(clientId:sendImpressions:onReady:));
+ (NeftaPlugin * _Nonnull)UnityInit:(NSString *_Nullable)appId clientId:(NSString *_Nullable)clientId sendImpressions:(BOOL)sendImpressions onReadyAsString:(void (^_Nonnull)(NSString*_Nonnull))onReadyAsString;
@end

@interface ISNeftaImpressionCollector : NSObject <LPMImpressionDataDelegate>
- (void)impressionDataDidSucceed:(LPMImpressionData *_Nonnull)impressionData;
@end

#endif /* ISNeftaCustomAdapter_h */
