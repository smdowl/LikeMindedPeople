//
//  #import "Facebook.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//


#import "Facebook.h"

@interface Facebook (iCatalog)

- (void)authorize_noSSO:(NSArray *)permissions;

+ (void)toggleSingleSignOn;

@end