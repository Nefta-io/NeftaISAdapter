//
//  ISNeftaCustomAdapter.m
//  Unity-iPhone
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import "ISNeftaCustomAdapter.h"


@implementation ISNeftaCustomAdapter

static NeftaPlugin_iOS *_plugin;
static NSMutableArray *_adapters;
static dispatch_semaphore_t _semaphore;

- (void)setAdapterDebug:(BOOL)adapterDebug {

}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    @synchronized (NeftaPlugin_iOS.Version) {
        if (_semaphore == nil) {
            _semaphore = dispatch_semaphore_create(1);
        }
        
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        if (_adapters != nil) {
            dispatch_semaphore_signal(_semaphore);
            [delegate onInitDidSucceed];
            return;
        }
        
        NSString *appId = [adData getString: @"appId"];
        if (appId == nil || appId.length == 0) {
            dispatch_semaphore_signal(_semaphore);
            [delegate onInitDidFailWithErrorCode:ISAdapterErrorMissingParams errorMessage:@"Missing appId"];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _plugin = [NeftaPlugin_iOS InitWithAppId: appId];
            
            _adapters = [NSMutableArray array];
            
            _plugin.OnLoadFail = ^(Placement *placement, NSString *error) {
                for (int i = 0; i < _adapters.count; i++) {
                    ISNeftaCustomAdapter *a = _adapters[i];
                    if ([a.placementId isEqualToString: placement._id] && a.state == 0) {
                        [a.listener adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:2 errorMessage:error];
                        [_adapters removeObject: a];
                        return;
                    }
                }
            };
            
            _plugin.OnLoad = ^(Placement *placement, NSInteger width, NSInteger height) {
                for (int i = 0; i < _adapters.count; i++) {
                    ISNeftaCustomAdapter *a = _adapters[i];
                    if ([a.placementId isEqualToString: placement._id] && a.state == 0) {
                        a.state = 1;
                        if (placement._type == TypesBanner) {
                            placement._isManualPosition = true;
                            [_plugin ShowMainWithId: placement._id];
                            UIView* v = [_plugin GetViewForPlacement: placement show: false];
                            v.frame = CGRectMake(0, 0, placement._width, placement._height);
                            [((id<ISBannerAdDelegate>)a.listener) adDidLoadWithView: v];
                        } else {
                            [a.listener adDidLoad];
                        }
                        return;
                    }
                }
            };
            
            _plugin.OnShow = ^(Placement *placement) {
                for (int i = 0; i < _adapters.count; i++) {
                    ISNeftaCustomAdapter *a = _adapters[i];
                    if ([a.placementId isEqualToString: placement._id] && a.state == 1) {
                        a.state = 2;
                        if (placement._type == TypesBanner) {
                            id<ISBannerAdDelegate> bannerListener = (id<ISBannerAdDelegate>) a.listener;
                            [bannerListener adDidOpen];
                            [bannerListener adWillPresentScreen];
                        } else {
                            id<ISAdapterAdInteractionDelegate> interactionListener = (id<ISAdapterAdInteractionDelegate>) a.listener;
                            [interactionListener adDidOpen];
                            [interactionListener adDidShowSucceed];
                            [interactionListener adDidBecomeVisible];
                        }
                        return;
                    }
                }
            };
            
            _plugin.OnClick = ^(Placement *placement) {
                for (int i = 0; i < _adapters.count; i++) {
                    ISNeftaCustomAdapter *a = _adapters[i];
                    if ([a.placementId isEqualToString: placement._id] && a.state == 2) {
                        id<ISAdapterAdDelegate> listener = a.listener;
                        [listener adDidClick];
                        return;
                    }
                }
            };
            
            _plugin.OnReward = ^(Placement *placement) {
                for (int i = 0; i < _adapters.count; i++) {
                    ISNeftaCustomAdapter *a = _adapters[i];
                    if ([a.placementId isEqualToString: placement._id] && a.state == 2) {
                        ISNeftaCustomAdapter *a = _adapters[i];
                        id<ISRewardedVideoAdDelegate> listener = (id<ISRewardedVideoAdDelegate>) a.listener;
                        [listener adRewarded];
                        return;
                    }
                }
            };
            
            _plugin.OnClose = ^(Placement *placement) {
                for (int i = 0; i < _adapters.count; i++) {
                    ISNeftaCustomAdapter *a = _adapters[i];
                    if ([a.placementId isEqualToString: placement._id] && a.state == 2) {
                        if (placement._type == TypesBanner) {
                            [((id<ISBannerAdDelegate>)a.listener) adDidDismissScreen];
                        } else {
                            id<ISAdapterAdInteractionDelegate> interactionListener = (id<ISAdapterAdInteractionDelegate>) a.listener;
                            [interactionListener adDidEnd];
                            [interactionListener adDidClose];
                        }
                        [_adapters removeObject: a];
                        return;
                    }
                }
            };
            
            [_plugin EnableAds: true];
            
            dispatch_semaphore_signal(_semaphore);
            [delegate onInitDidSucceed];
        });
    }
}

- (NSString *) networkSDKVersion {
    return NeftaPlugin_iOS.Version;
}

- (NSString *) adapterVersion {
    return @"1.3.1";
}

+ (void)ApplyRenderer:(UIViewController *)viewController {
    [_plugin PrepareRendererWithViewController: viewController];
}

- (void)Load:(NSString *)pId delgate:(id<ISAdapterAdDelegate>)delegate {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    _placementId = pId;
    _state = 0;
    _listener = delegate;
    [_adapters addObject: self];
    [_plugin LoadWithId: pId];
    dispatch_semaphore_signal(_semaphore);
}

- (BOOL)IsReady:(NSString *)pId {
    return [_plugin IsReadyWithId: pId];
}

- (void)Show:(NSString *)pId {
    [_plugin ShowWithId: pId];
}

- (void)Close:(NSString *)pId {
    [_plugin CloseWithId: pId];
}
@end
