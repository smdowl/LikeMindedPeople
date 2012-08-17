//
//  ServiceAdapter.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class GeofenceLocation;
@interface ServiceAdapter : NSObject {
    NSMutableData *responseData;
}

+ (void)uploadUserProfile:(NSArray *)profile forUser:(NSString *)userId success:(void (^)(id))success;

+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success;

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location radius:(CGFloat)radius success:(void (^)(NSArray *))success;

+ (void)enterGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success;

+ (void)exitGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success;

+ (void)getDirectionsFromLocation:(CLLocationCoordinate2D)from toLocation:(CLLocationCoordinate2D)to onSuccess:(void(^)(NSDictionary *))success;

+ (void)getGoogleSearchResultsForUser:(NSString *)userId atLocation:(CLLocationCoordinate2D)location withName:(NSString *)name withType:(NSString *)type success:(void (^)(NSArray *))success failure:(void (^)(void))failure;

// Testing methods
+ (void)testService;
+ (void)getAllUsersWithSuccess:(void (^)(id))success;

@end
