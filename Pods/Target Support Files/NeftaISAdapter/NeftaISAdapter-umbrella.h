#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ISNeftaCustomAdapter.h"
#import "ISNeftaCustomBanner.h"
#import "ISNeftaCustomInterstitial.h"
#import "ISNeftaCustomRewardedVideo.h"
#import "NeftaIsAdapter.h"

FOUNDATION_EXPORT double NeftaISAdapterVersionNumber;
FOUNDATION_EXPORT const unsigned char NeftaISAdapterVersionString[];

