//
//  ISNeftaCustomAdapter.m
//  Unity-iPhone
//
//  Created by Tomaz Treven on 14/11/2023.
//

#import "ISNeftaCustomAdapter.h"


@interface MListener : NSObject
@property (nonatomic, strong) NSString* placementId;
@property (nonatomic) int state;
@property (nonatomic, strong) id<ISAdapterAdDelegate> listener;
-(instancetype)initWithId:(NSString *)placementId listener:(id<ISAdapterAdDelegate>)listener;
@end
@implementation MListener
-(instancetype)initWithId:(NSString *)placementId listener:(id<ISAdapterAdDelegate>)listener {
    self = [super init];
    if (self) {
        _placementId = placementId;
        _state = 0;
        _listener = listener;
    }
    return self;
}
@end

@implementation ISNeftaCustomAdapter

static NeftaPlugin_iOS *_plugin;
static NSMutableArray *_listeners;
static dispatch_semaphore_t _semaphore;

- (void)setAdapterDebug:(BOOL)adapterDebug {
    [NeftaPlugin_iOS EnableLogging: adapterDebug];
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {
    @synchronized (NeftaPlugin_iOS.Version) {
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
            
            _listeners = [NSMutableArray array];
            
            _plugin.OnLoadFail = ^(Placement *placement, NSString *error) {
                for (int i = 0; i < _listeners.count; i++) {
                    MListener *ml = _listeners[i];
                    if ([ml.placementId isEqualToString: placement._id] && ml.state == 0) {
                        [ml.listener adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal errorCode:2 errorMessage:error];
                        [_listeners removeObject: ml];
                        return;
                    }
                }
            };
            
            _plugin.OnLoad = ^(Placement *placement) {
                for (int i = 0; i < _listeners.count; i++) {
                    MListener *ml = _listeners[i];
                    if ([ml.placementId isEqualToString: placement._id] && ml.state == 0) {
                        ml.state = 1;
                        if (placement._type == TypesBanner) {
                            placement._isManualPosition = true;
                            [_plugin ShowMainWithId: placement._id];
                            UIView* v = [_plugin GetViewForPlacement: placement show: false];
                            v.frame = CGRectMake(0, 0, placement._width, placement._height);
                            [((id<ISBannerAdDelegate>)ml.listener) adDidLoadWithView: v];
                        } else {
                            [ml.listener adDidLoad];
                        }
                        return;
                    }
                }
            };
            
            _plugin.OnShow = ^(Placement *placement, NSInteger width, NSInteger height) {
                for (int i = 0; i < _listeners.count; i++) {
                    MListener *ml = _listeners[i];
                    if ([ml.placementId isEqualToString: placement._id] && ml.state == 0) {
                        ml.state = 2;
                        if (placement._type == TypesBanner) {
                            id<ISBannerAdDelegate> bannerListener = (id<ISBannerAdDelegate>) ml.listener;
                            [bannerListener adDidOpen];
                            [bannerListener adWillPresentScreen];
                        } else {
                            id<ISAdapterAdInteractionDelegate> interactionListener = (id<ISAdapterAdInteractionDelegate>) ml.listener;
                            [interactionListener adDidOpen];
                            [interactionListener adDidShowSucceed];
                            [interactionListener adDidBecomeVisible];
                        }
                        return;
                    }
                }
            };
            
            _plugin.OnClick = ^(Placement *placement) {
                for (int i = 0; i < _listeners.count; i++) {
                    MListener *ml = _listeners[i];
                    if ([ml.placementId isEqualToString: placement._id] && ml.state == 2) {
                        id<ISAdapterAdDelegate> listener = ml.listener;
                        [listener adDidClick];
                        return;
                    }
                }
            };
            
            _plugin.OnReward = ^(Placement *placement) {
                for (int i = 0; i < _listeners.count; i++) {
                    MListener *ml = _listeners[i];
                    if ([ml.placementId isEqualToString: placement._id] && ml.state == 2) {
                        MListener *ml = _listeners[i];
                        id<ISRewardedVideoAdDelegate> listener = (id<ISRewardedVideoAdDelegate>) ml.listener;
                        [listener adRewarded];
                        return;
                    }
                }
            };
            
            _plugin.OnClose = ^(Placement *placement) {
                for (int i = 0; i < _listeners.count; i++) {
                    MListener *ml = _listeners[i];
                    if ([ml.placementId isEqualToString: placement._id] && ml.state == 2) {
                        if (placement._type == TypesBanner) {
                            [((id<ISBannerAdDelegate>)ml.listener) adDidDismissScreen];
                        } else {
                            id<ISAdapterAdInteractionDelegate> interactionListener = (id<ISAdapterAdInteractionDelegate>) ml.listener;
                            [interactionListener adDidEnd];
                            [interactionListener adDidClose];
                        }
                        [_listeners removeObject: ml];
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
    return @"1.2.7";
}

+ (void)ApplyRenderer:(UIViewController *)viewController {
    [_plugin PrepareRendererWithViewController: viewController];
}

- (void)Load:(NSString *)pId delgate:(id<ISAdapterAdDelegate>)delegate {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    
    MListener *listener = [[MListener alloc] initWithId: pId listener: delegate];
    [_listeners addObject: listener];
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
