//
//  ISNeftaCustomInterstitial.m
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import <Foundation/Foundation.h>

#import "ISNeftaCustomInterstitial.h"

@implementation ISNeftaCustomInterstitial

- (void)loadAdWithAdData:(nonnull ISAdData *)adData delegate:(nonnull id<ISInterstitialAdDelegate>)delegate {
    NSString *placementId = [adData getString: @"placementId"];
    _interstitial = [[NInterstitial alloc] initWithId: placementId];
    _interstitial._listener = self;
    _listener = delegate;
}

- (BOOL)isAdAvailableWithAdData:(nonnull ISAdData *)adData {
    return [_interstitial CanShow] == NAd.Ready;
}

- (void)showAdWithViewController:(nonnull UIViewController *)viewController adData:(nonnull ISAdData *)adData delegate:(nonnull id<ISInterstitialAdDelegate>)delegate {
    [NeftaPlugin._instance PrepareRendererWithViewController: viewController];
    
    [_interstitial Show];
}

- (void)OnLoadFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    [_listener adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:error._code errorMessage:error._message];
}
- (void)OnLoadWithAd:(NAd * _Nonnull)ad width:(NSInteger)width height:(NSInteger)height {
    [_listener adDidLoad];
}
- (void)OnShowFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {

}
- (void)OnShowWithAd:(NAd * _Nonnull)ad {
    [_listener adDidShowSucceed];
    [_listener adDidBecomeVisible];
}
- (void)OnClickWithAd:(NAd * _Nonnull)ad {
    [_listener adDidClick];
}
- (void)OnCloseWithAd:(NAd * _Nonnull)ad {
    [_listener adDidEnd];
    [_listener adDidClose];
}
@end
