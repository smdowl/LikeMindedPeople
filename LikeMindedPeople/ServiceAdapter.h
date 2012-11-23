//
//  ServiceAdapter.h
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class GeofenceLocation, RadiiResultDTO, LocationDetailsDTO, PRProfile;
@interface ServiceAdapter : NSObject {
    NSMutableData *responseData;
}

+ (void)uploadUserProfile:(NSDictionary *)profile userDetails:(NSDictionary *)userDetails success:(void (^)(id))success failure:(void (^)(NSError *))failure;

+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success failure:(void (^)(NSError *))failure;

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location radius:(CGFloat)radius success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure;

+ (void)getLocationDetails:(RadiiResultDTO *)location userId:(NSString *)userId success:(void (^)(LocationDetailsDTO *details))success failure:(void (^)(NSError *))failure;

+ (void)enterGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success failure:(void (^)(NSError *))failure;

+ (void)exitGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success failure:(void (^)(NSError *))failure;

+ (void)getDirectionsFromLocation:(CLLocationCoordinate2D)from toLocation:(CLLocationCoordinate2D)to onSuccess:(void(^)(NSDictionary *))success failure:(void (^)(NSError *))failure;

//+ (void)getGoogleSearchResultsForUser:(NSString *)userId atLocation:(CLLocationCoordinate2D)location withName:(NSString *)name withType:(NSString *)type success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure;
+ (void)getFourSquareSearchResultsForUser:(NSString *)userId atLocation:(CLLocationCoordinate2D)location withQuery:(NSString *)query type:(NSString *)type success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure;

+ (void)ratePlace:(RadiiResultDTO *)place user:(NSString *)userId up:(BOOL)up;

// Testing methods
+ (void)getAllUsersWithSuccess:(void (^)(id))success;

@end
