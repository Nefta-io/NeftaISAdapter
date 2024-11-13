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
    [NeftaPlugin._instance PrepareRendererWithViewController: viewController];
    
    NSString *placementId = [adData getString: @"placementId"];
    _banner = [[NBanner alloc] initWithId: placementId position: PositionNone];
    _banner._listener = self;
    _listener = delegate;
}

- (void) destroyAdWithAdData:(nonnull ISAdData *)adData {
    [_banner Close];
}

- (void)OnLoadFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    [_listener adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:error._code errorMessage:error._message];
}
- (void)OnLoadWithAd:(NAd * _Nonnull)ad width:(NSInteger)width height:(NSInteger)height {
    //_banner._isManualPosition = true;
    [_banner Show];
    UIView *v = [_banner GetView];
    v.frame = CGRectMake(0, 0, _banner._placement._width, _banner._placement._height);
    [_listener adDidLoadWithView: v];
}
- (void)OnShowFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {

}
- (void)OnShowWithAd:(NAd * _Nonnull)ad {
    [_listener adDidOpen];
    [_listener adWillPresentScreen];
}
- (void)OnClickWithAd:(NAd * _Nonnull)ad {
    [_listener adDidClick];
}
- (void)OnCloseWithAd:(NAd * _Nonnull)ad {
    [_listener adDidDismissScreen];
}
@end
