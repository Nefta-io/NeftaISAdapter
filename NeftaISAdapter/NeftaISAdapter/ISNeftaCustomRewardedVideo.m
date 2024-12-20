//
//  ISNeftaCustomRewardedVideo.m
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import <Foundation/Foundation.h>

#import "ISNeftaCustomRewardedVideo.h"

@implementation ISNeftaCustomRewardedVideo

- (void)loadAdWithAdData:(nonnull ISAdData *)adData delegate:(nonnull id<ISRewardedVideoAdDelegate>)delegate {
    NSString *placementId = [adData getString: @"placementId"];
    _rewarded = [[NRewarded alloc] initWithId: placementId];
    _rewarded._listener = self;
    _listener = delegate;
    
    [_rewarded Load];
}

- (BOOL)isAdAvailableWithAdData:(nonnull ISAdData *)adData {
    return [_rewarded CanShow] == NAd.Ready;
}

- (void)showAdWithViewController:(nonnull UIViewController *)viewController adData:(nonnull ISAdData *)adData delegate:(nonnull id<ISRewardedVideoAdDelegate>)delegate {
    [NeftaPlugin._instance PrepareRendererWithViewController: viewController];
    
    [_rewarded ShowThreaded];
}

- (void)OnLoadFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    [_listener adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:error._code errorMessage:error._message];
}
- (void)OnLoadWithAd:(NAd * _Nonnull)ad width:(NSInteger)width height:(NSInteger)height {
    [_listener adDidLoad];
}
- (void)OnShowFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    [_listener adDidFailToShowWithErrorCode: error._code errorMessage: error._message];
}
- (void)OnShowWithAd:(NAd * _Nonnull)ad {
    [_listener adDidOpen];
    [_listener adDidBecomeVisible];
    [_listener adDidShowSucceed];
}
- (void)OnClickWithAd:(NAd * _Nonnull)ad {
    [_listener adDidClick];
}
- (void)OnRewardWithAd:(NAd * _Nonnull)ad {
    [_listener adRewarded];
}
- (void)OnCloseWithAd:(NAd * _Nonnull)ad {
    [_listener adDidEnd];
    [_listener adDidClose];
}

@end
