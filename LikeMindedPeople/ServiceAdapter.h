//
//  ServiceAdapter.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class GeofenceLocation, RadiiResultDTO, LocationDetailsDTO;
@interface ServiceAdapter : NSObject {
    NSMutableData *responseData;
}

+ (void)uploadUserProfile:(NSArray *)profile forUser:(NSString *)userId success:(void (^)(id))success failure:(void (^)(void))failure;

+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success failure:(void (^)(void))failure;

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location radius:(CGFloat)radius success:(void (^)(NSArray *))success failure:(void (^)(void))failure;

+ (void)getLocationDetails:(RadiiResultDTO *)location userId:(NSString *)userId success:(void (^)(LocationDetailsDTO *details))success failure:(void (^)(void))failure;

+ (void)enterGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success failure:(void (^)(void))failure;

+ (void)exitGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success failure:(void (^)(void))failure;

+ (void)getDirectionsFromLocation:(CLLocationCoordinate2D)from toLocation:(CLLocationCoordinate2D)to onSuccess:(void(^)(NSDictionary *))success failure:(void (^)(void))failure;

//+ (void)getGoogleSearchResultsForUser:(NSString *)userId atLocation:(CLLocationCoordinate2D)location withName:(NSString *)name withType:(NSString *)type success:(void (^)(NSArray *))success failure:(void (^)(void))failure;
+ (void)getFourSquareSearchResultsForUser:(NSString *)userId atLocation:(CLLocationCoordinate2D)location withQuery:(NSString *)query success:(void (^)(NSArray *))success failure:(void (^)(void))failure;

// Testing methods
+ (void)getAllUsersWithSuccess:(void (^)(id))success;

@end
