//
//  ServiceAdapter.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import <Foundation/Foundation.h>

@class CLLocation;
@interface ServiceAdapter : NSObject {
    NSMutableData *responseData;
}

+ (void)testService;

+ (void)getAllUsersWithSuccess:(void (^)(id))success;

+ (void)callServiceWithPath:(NSString *)path
                 httpMethod:(NSString *)method
           postPrefixString:(NSString *)prefix
            dataObj:(id)dataObj
            success:(void (^)(id))success;

+ (void)uploadUserProfile:(NSArray *)profile forUser:(NSString *)userId success:(void (^)(id))success;

+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success;

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location success:(void (^)(NSArray *))success;

@end
