//
//  RDRadiiManager.h
//  LikeMindedPeople
//
//  Created by Lucas Coelho on 11/13/12.
//
//

#import <Foundation/Foundation.h>

#define RD_MANAGER [RDRadiiManager sharedRDRadiiManager]

@interface RDRadiiManager : NSObject

+ (RDRadiiManager *)sharedRDRadiiManager;
- (void)rateAppInStore;

@end
