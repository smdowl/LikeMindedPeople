
#import <Foundation/Foundation.h>

typedef enum  {
    QLPlaceEventTypeAt = 1,
    QLPlaceEventTypeLeft = 2,
} QLPlaceEventType;

typedef enum  {
    QLPlaceTypePrivate = 0,
    QLPlaceTypeOrganization = 1,
} QLPlaceType;

@interface QLPlaceEvent : NSObject

@property (nonatomic, assign) long placeId;
@property (nonatomic, strong) NSString *placeName;
@property (nonatomic, assign) QLPlaceType placeType;
@property (nonatomic, assign) QLPlaceEventType eventType;
@property (nonatomic, strong) NSDate *time;

@end
