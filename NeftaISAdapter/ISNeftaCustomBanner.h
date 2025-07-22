//
//  ISNeftaCustomBanner.h
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#ifndef ISNeftaCustomBanner_h
#define ISNeftaCustomBanner_h

#import "ISNeftaCustomAdapter.h"
#import <NeftaSDK/NeftaSDK-Swift.h>

@interface ISNeftaCustomBanner : ISBaseBanner<NBannerListener>
@property NBanner * _Nonnull banner;
@property (nonatomic, weak) id<ISBannerAdDelegate> listener;
+ (NSString * _Nullable) GetLastAuctionId;
+ (NSString * _Nullable) GetLastCreativeId;
@end

#endif /* ISNeftaCustomBanner_h */
