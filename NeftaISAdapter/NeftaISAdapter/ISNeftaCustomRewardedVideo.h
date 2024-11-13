//
//  ISNeftaCustomRewardedVideo.h
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#ifndef ISNeftaCustomRewardedVideo_h
#define ISNeftaCustomRewardedVideo_h

#import "ISNeftaCustomAdapter.h"

@interface ISNeftaCustomRewardedVideo : ISBaseRewardedVideo<NRewardedListener>
@property NRewarded * _Nonnull rewarded;
@property (nonatomic, weak) id<ISRewardedVideoAdDelegate> listener;
@end

#endif /* ISNeftaCustomRewardedVideo_h */
