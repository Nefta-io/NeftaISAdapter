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
+ (NeftaPlugin*)initWithAppId:(NSString *)appId;
+ (NeftaPlugin*)initWithAppId:(NSString *)appId sendImpressions:(BOOL)sendImpressions;
@end

@interface ISNeftaImpressionCollector : NSObject <ISImpressionDataDelegate>
- (void)impressionDataDidSucceed:(ISImpressionData *)impressionData;
@end

#endif /* ISNeftaCustomAdapter_h */
