//
//  ISNeftaCustomRewardedVideo.m
//  NeftaISAdapter
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import <Foundation/Foundation.h>

#import "ISNeftaCustomRewardedVideo.h"

static NSString* _lastCreativeId;
static NSString* _lastAuctionId;

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
    [_rewarded ShowThreaded: viewController];
}

- (void)OnLoadFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    ISAdapterErrorType errorType = [ISNeftaCustomAdapter NLoadToAdapterError: error];
    [_listener adDidFailToLoadWithErrorType: errorType errorCode: error._code errorMessage: error._message];
}
- (void)OnLoadWithAd:(NAd * _Nonnull)ad width:(NSInteger)width height:(NSInteger)height {
    [_listener adDidLoad];
}
- (void)OnShowFailWithAd:(NAd * _Nonnull)ad error:(NError * _Nonnull)error {
    [_listener adDidFailToShowWithErrorCode: error._code errorMessage: error._message];
}
- (void)OnShowWithAd:(NAd * _Nonnull)ad {
    _lastAuctionId = ad._bid._auctionId;
    _lastCreativeId = ad._bid._creativeId;
    [_listener adDidShowSucceed];
    [_listener adDidOpen];
    [_listener adDidBecomeVisible];
    [_listener adDidStart];
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

+ (NSString*) GetLastAuctionId {
    return _lastAuctionId;
}
+ (NSString*) GetLastCreativeId {
    return _lastCreativeId;
}
@end
