//
//  ISNeftaCustomBanner.m
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import <Foundation/Foundation.h>

#import "ISNeftaCustomBanner.h"

@implementation ISNeftaCustomBanner

- (void) loadAdWithAdData:(nonnull ISAdData *)adData viewController:(UIViewController *)viewController size:(ISBannerSize *)size delegate:(nonnull id<ISBannerAdDelegate>)delegate {
    [self trySetAdapter];
    [ISNeftaCustomAdapter ApplyRenderer: viewController];
    
    NSString *placementId = [adData getString: @"placementId"];
    if (placementId != nil && placementId.length > 0) {
        [_adapter Load: placementId delgate: delegate];
    }
}

- (void) destroyAdWithAdData:(nonnull ISAdData *)adData {
    [self trySetAdapter];
    
    NSString *placementId = [adData getString: @"placementId"];
    if (placementId != nil && placementId.length > 0) {
        [_adapter Close: placementId];
    }
}

- (void) trySetAdapter {
    if (_adapter == nil) {
        _adapter = (ISNeftaCustomAdapter *)[self getNetworkAdapter];
    }
}
@end
