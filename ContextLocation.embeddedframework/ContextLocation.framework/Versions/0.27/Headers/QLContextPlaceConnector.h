
#import <Foundation/Foundation.h>

@class QLPlace;
@class QLPlaceEvent;

@protocol QLContextPlaceConnectorDelegate <NSObject>

@optional

- (void)didGetPlaceEvent:(QLPlaceEvent *)placeEvent;

- (void)didGetContentDescriptors:(NSArray *)contentDescriptors;

- (void)placesPermissionDidChange:(BOOL)placesPermission;

- (void)privatePlacesDidChange:(NSArray *)privatePlaces;

@end


@interface QLContextPlaceConnector : NSObject

@property (assign) id<QLContextPlaceConnectorDelegate> delegate;
@property (nonatomic, readonly) BOOL isPlacesEnabled;

- (void)requestLatestPlaceEventsAndOnSuccess:(void (^)(NSArray *placeEvents))success 
                                     failure:(void (^)(NSError *error))failure;

- (void)allOrganizationPlacesAndOnSuccess:(void (^)(NSArray *places))success 
                               failure:(void (^)(NSError *error))failure;

- (void)requestContentHistoryAndOnSuccess:(void (^)(NSArray *contentHistories))success 
                              failure:(void (^)(NSError *error))failure;

- (void)allPlacesAndOnSuccess:(void (^)(NSArray *places))success failure:(void (^)(NSError *error))failure;

- (void)createPlace:(QLPlace *)place success:(void (^)(QLPlace *place))success failure:(void (^)(NSError *error))failure;

- (void)updatePlace:(QLPlace *)place success:(void (^)(QLPlace *place))success failure:(void (^)(NSError *error))failure;

- (void)deletePlaceWithId:(long long)placeId success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (void)allPrivatePointsOfInterestAndOnSuccess:(void (^)(NSArray *privatePointsOfInterest))success failure:(void (^)(NSError *error))failure;

@end
