//
//  ISNeftaCustomAdapter.m
//  Unity-iPhone
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import "ISNeftaCustomAdapter.h"

@implementation ISNeftaCustomAdapter

static NeftaPlugin_iOS *_plugin;
static NSMutableDictionary<NSString *, id<ISAdapterAdDelegate>> *_listeners;
dispatch_semaphore_t _semaphore;

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    if (_semaphore == nil) {
        _semaphore = dispatch_semaphore_create(1);
    }
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if (_listeners != nil) {
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
        
        _listeners = [[NSMutableDictionary alloc] init];
        
        _plugin.OnLoadFail = ^(Placement *placement, NSString *error) {
            id<ISAdapterAdDelegate> listener = _listeners[placement._id];
            [listener adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:2 errorMessage:error];
        };
        
        _plugin.OnLoad = ^(Placement *placement) {
            id<ISAdapterAdDelegate> listener = _listeners[placement._id];
            if (placement._type == TypesBanner) {
                WebPlacement *webPlacement = (WebPlacement *)placement;
                UIView *view = webPlacement._bufferWebController;
                [((id<ISBannerAdDelegate>)listener) adDidLoadWithView: view];
                [_plugin ShowWithId: placement._id];
            } else {
                [listener adDidLoad];
            }
        };
        
        _plugin.OnShow = ^(Placement *placement, NSInteger width, NSInteger height) {
            id<ISAdapterAdDelegate> listener = _listeners[placement._id];
            if (placement._type == TypesBanner) {
                id<ISBannerAdDelegate> bannerListener = (id<ISBannerAdDelegate>) listener;
                [bannerListener adDidOpen];
                [bannerListener adWillPresentScreen];
            } else {
                id<ISAdapterAdInteractionDelegate> interactionListener = (id<ISAdapterAdInteractionDelegate>) listener;
                [interactionListener adDidOpen];
                [interactionListener adDidShowSucceed];
                [interactionListener adDidBecomeVisible];
            }
        };
        
        _plugin.OnClick = ^(Placement *placement) {
            id<ISAdapterAdDelegate> listener = _listeners[placement._id];
            [listener adDidClick];
        };
        
        _plugin.OnClose = ^(Placement *placement) {
            id<ISAdapterAdDelegate> listener = _listeners[placement._id];
            if (placement._type == TypesBanner) {
                [((id<ISBannerAdDelegate>)listener) adDidDismissScreen];
            } else {
                id<ISAdapterAdInteractionDelegate> interactionListener = (id<ISAdapterAdInteractionDelegate>) listener;
                [interactionListener adDidEnd];
                [interactionListener adDidClose];
            }
        };
        
        [_plugin EnableAds: true];
        
        dispatch_semaphore_signal(_semaphore);
        [delegate onInitDidSucceed];
    });
}

- (NSString *) networkSDKVersion {
    return NeftaPlugin_iOS.Version;
}

- (NSString *) adapterVersion {
    return @"1.1.1";
}

+ (void)ApplyRenderer:(UIViewController *)viewController {
    [_plugin PrepareRendererWithViewController: viewController];
}

- (void) Load:(NSString *)pId delgate:(id<ISAdapterAdDelegate>)delegate {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    _listeners[pId] = delegate;
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
