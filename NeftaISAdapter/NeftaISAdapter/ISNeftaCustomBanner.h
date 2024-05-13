//
//  ISNeftaCustomBanner.h
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#ifndef ISNeftaCustomBanner_h
#define ISNeftaCustomBanner_h

#import "ISNeftaCustomAdapter.h"

@interface ISNeftaCustomBanner : ISBaseBanner

@property (nonatomic, strong) NSString* placementId;
@property (nonatomic) int state;
@property (nonatomic, strong) id<ISAdapterAdDelegate> listener;

@property ISNeftaCustomAdapter *adapter;

@end

#endif /* ISNeftaCustomBanner_h */
