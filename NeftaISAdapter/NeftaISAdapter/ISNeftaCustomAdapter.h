//
//  ISNeftaCustomAdapter.h
//  UnityFramework
//
//  Created by Tomaz Treven on 14/11/2023.
//

#ifndef ISNeftaCustomAdapter_h
#define ISNeftaCustomAdapter_h

#import <Foundation/Foundation.h>

#import <IronSource/IronSource.h>

#import <NeftaSDK/NeftaSDK-Swift.h>

@interface ISNeftaCustomAdapter : ISBaseNetworkAdapter

@property(nonatomic, strong) NSString* placementId;
@property(nonatomic) int state;
@property(nonatomic, strong) id<ISAdapterAdDelegate> listener;

+ (void)ApplyRenderer:(UIViewController *)viewController;
- (void)Load:(NSString *)pId delgate:(id<ISAdapterAdDelegate>)delegate;
- (BOOL)IsReady:(NSString *)pId;
- (void)Show:(NSString *)pId;
- (void)Close:(NSString *)pId;
@end

#endif /* ISNeftaCustomAdapter_h */
