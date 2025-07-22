//
//  ISNeftaCustomRewardedVideo.h
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#ifndef ISNeftaCustomRewardedVideo_h
#define ISNeftaCustomRewarded_h

#import "ISNeftaCustomAdapter.h"

@interface ISNeftaCustomRewardedVideo : ISBaseRewardedVideo<NRewardedListener>
@property NRewarded * _Nonnull rewarded;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> listener;
+ (NSString * _Nullable) GetLastAuctionId;
+ (NSString * _Nullable) GetLastCreativeId;
@end

#endif /* ISNeftaCustomRewardedVideo_h */
