
#import <Foundation/Foundation.h>
#import <Common/QLAvailability.h>

typedef enum  {
    QLPlaceEventTypeAt = 1,
    QLPlaceEventTypeLeft = 2,
} QLPlaceEventType;

typedef enum  {
    QLPlaceTypePrivate = 0,
    QLPlaceTypeOrganization = 1,
} QLPlaceType;

@class QLPlace;

@interface QLPlaceEvent : NSObject

@property (nonatomic, assign) QLPlaceEventType eventType;
@property (nonatomic, strong) NSDate *time;
@property (nonatomic, strong) QLPlace *place;
@property (nonatomic, assign) QLPlaceType placeType;
@property (nonatomic, assign) long placeId DEPRECATED;
@property (nonatomic, strong) NSString *placeName DEPRECATED;

@end
