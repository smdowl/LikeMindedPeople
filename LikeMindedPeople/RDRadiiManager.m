//
//  RDRadiiManager.m
//  LikeMindedPeople
//
//  Created by Lucas Coelho on 11/13/12.
//
//

#import "RDRadiiManager.h"
#import "SynthesizeSingleton.h"
#import "WPReachability.h"


#define kAppleAppID @"503679675"


@implementation RDRadiiManager

SYNTHESIZE_SINGLETON_FOR_CLASS(RDRadiiManager);


- (void)rateAppInStore
{
#if TARGET_IPHONE_SIMULATOR
	NSLog(@"APPIRATER NOTE: iTunes App Store is not supported on the iOS simulator. Unable to open App Store page.");
#else
	NSError * error = [self testReachability];
	if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network error"
                                                        message:@"Check your Internet connection"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
		return;
	}

    NSString * templateReviewURL = [NSString stringWithFormat:@"%@",@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID"];

	NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", kAppleAppID]];
    
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
#endif
}

- (NSError *)testReachability
{
	WPReachability * reachability = [WPReachability sharedReachability];
	NetworkStatus internetConnectionStatus = [reachability internetConnectionStatus];
	if(internetConnectionStatus == NotReachable) {
		return [NSError errorWithDomain:NSURLErrorDomain
								   code:NSURLErrorNetworkConnectionLost
							   userInfo:nil];
	}
	return nil;
}

@end
