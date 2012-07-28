//
//  #import "Facebook.h"   @interface Facebook (iCatalog)   - (void)authorize_noSSO:(NSArray *)permissions;   + (void)toggleSingleSignOn;  Facebook+NoSSO
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import "Facebook+iCatalog.h"
#import "Facebook.h"
#import "NSObject+DTRuntime.h"

@interface Facebook ()

- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth
                    safariAuth:(BOOL)trySafariAuth;
@end

@implementation Facebook (iCatalog)

- (void)authorize_noSSO:(NSArray *)permissions
{
	[self setValue:permissions forKey:@"permissions"];
    
	[self authorizeWithFBAppAuth:NO safariAuth:NO];
}

+ (void)toggleSingleSignOn
{
    NSLog(@"toggleSingleSignOn");
	[Facebook swizzleMethod:@selector(authorize:) withMethod:@selector(authorize_noSSO:)];
}

@end