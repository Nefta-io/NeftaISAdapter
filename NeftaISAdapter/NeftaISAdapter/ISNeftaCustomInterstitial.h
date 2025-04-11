//
//  ISNeftaCustomInterstitial.h
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#ifndef ISNeftaCustomInterstitial_h
#define ISNeftaCustomInterstitial_h

#import "ISNeftaCustomAdapter.h"
#import <NeftaSDK/NeftaSDK-Swift.h>

@interface ISNeftaCustomInterstitial : ISBaseInterstitial<NInterstitialListener>
@property NInterstitial * _Nonnull interstitial;
@property (nonatomic, weak) id<ISInterstitialAdDelegate> listener;
+ (NSString * _Nullable) GetLastAuctionId;
+ (NSString * _Nullable) GetLastCreativeId;
@end

#endif /* ISNeftaCustomInterstitial_h */
