//
//  ServiceAdapter.m
//  LikeMindedPeople
//
//  Created by Brian Fields on 7/28/12.
//
//

#import "ServiceAdapter.h"
#import "AFJSONRequestOperation.h"
#import <ContextLocation/QLPlace.h>
#import <ContextLocation/QLGeofenceCircle.h>
#import "GeofenceLocation.h"
#import "RadiiResultDTO.h"
#import "ServerKeys.h"

#define DEBUG_MODE YES

#define SAN_FRAN_LATITUDE_MIN 37.755787
#define SAN_FRAN_LATITUDE_MAX 37.797306

#define SAN_FRAN_LONGITUDE_MIN -122.430439
#define SAN_FRAN_LONGITUDE_MAX -122.378769

#define TEST_GRID_WIDTH 3

#define TEST_RADIUS 50

@interface ServiceAdapter()
+ (void)_callServiceWithPath:(NSString *)path
				  httpMethod:(NSString *)method
			postPrefixString:(NSString *)prefix
					 dataObj:(id)dataObj
					 success:(void (^)(id))success;
@end

@implementation ServiceAdapter

// TODO: Use data from facebook
+ (void)uploadUserProfile:(NSArray *)profile forUser:(NSString *)userId success:(void (^)(id))success
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *userStuff = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"German", @"name", @"Larrain", @"last_name", userId, @"fb_id", nil];
    
    [d setObject:userStuff forKey:@"user"];
    [d setObject:profile forKey:@"profile"];
	
    [ServiceAdapter _callServiceWithPath:@"users.json" httpMethod:@"POST" postPrefixString:@"user_profile=" dataObj:d success:success];
	
	success(nil);
}

+ (void)updateCurrentLocationForUser:(NSString *)userId location:(CLLocation *)location success:(void (^)(id))success
{
	NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *dloc = [[NSMutableDictionary alloc] init];
    [dloc setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"lattitude"];
    [dloc setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
    [dloc setObject:@"10" forKey:@"radius"];
    [d setObject:dloc forKey:@"location"];
    
    [d setObject:userId forKey:@"fb_id"];
    // TODO: Get radius somehow
    
    
    [ServiceAdapter _callServiceWithPath:[NSString stringWithFormat:@"update_location/%@.json",userId] httpMethod:@"POST" postPrefixString:@"location=" dataObj:dloc success:success];
	
    success(nil);
}


// pointsOfInterest: array of QLPlace
+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success
{
	NSMutableDictionary *ds = [[NSMutableDictionary alloc] init];
    //[d setObject:userId forKey:@"uid"];
    
    NSMutableArray *pois = [[NSMutableArray alloc] init];
    
    [pointsOfInterest enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        QLPlace *p = (QLPlace *)obj;
		
        QLGeoFenceCircle *c = (QLGeoFenceCircle *)p.geoFence;
        
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        [d setObject:[NSString stringWithFormat:@"%f",c.latitude] forKey:@"latitude"];
        [d setObject:[NSString stringWithFormat:@"%f",c.longitude] forKey:@"longitude"];
        [d setObject:[NSString stringWithFormat:@"%f",c.radius] forKey:@"radius"];
        [d setObject:[NSString stringWithFormat:@"%d",idx+1] forKey:@"rank"];
		
        [pois addObject:d];
    }];
	
    [ds setObject:pois forKey:@"pois"];
    
    [ServiceAdapter _callServiceWithPath:[NSString stringWithFormat:@"users/%@.json",userId] httpMethod:@"POST" postPrefixString:@"pois=" dataObj:ds success:success];
    
	success(nil);
}

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location radius:(CGFloat)radius success:(void (^)(NSArray *))success
{    
    // Make "YES" for testing, "NO" to use servers.
    if (!DEBUG_MODE) {
		NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
		//[d setObject:userId forKey:@"uid"];
		[d setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"lattitude"];
		[d setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
		// Filter in miles
		[d setObject:@"500000" forKey:@"filter"];
		
        [ServiceAdapter _callServiceWithPath:[NSString stringWithFormat:@"filter_locations/%@.json",userId] httpMethod:@"POST" postPrefixString:@"location_filter=" dataObj:d success:success];
    } else {
		
        NSMutableArray *places = [NSMutableArray array];
		
		CLLocationCoordinate2D coordinate = location.coordinate;
		
		CGFloat approximateLatitudeChange = radius / 111000;
		CGFloat approximateLongitudeChange = radius / (111000 * cosf(coordinate.latitude));
		
//		CGFloat latitudeStep = (SAN_FRAN_LATITUDE_MAX - SAN_FRAN_LATITUDE_MIN) / TEST_GRID_WIDTH;
//		CGFloat longitudeStep = (SAN_FRAN_LONGITUDE_MAX - SAN_FRAN_LONGITUDE_MIN) / TEST_GRID_WIDTH;

		CGFloat latitudeStep = approximateLatitudeChange / TEST_GRID_WIDTH;
		CGFloat longitudeStep = approximateLongitudeChange / TEST_GRID_WIDTH;
		
		CGFloat startLat = coordinate.latitude - approximateLatitudeChange / 2;
		CGFloat startLong = coordinate.longitude - approximateLongitudeChange / 2;
		
		for (int i=0; i<TEST_GRID_WIDTH; i++)
		{
			for (int j=0; j<TEST_GRID_WIDTH; j++)
			{
				// Create the containing object
				GeofenceLocation *newLocation = [[GeofenceLocation alloc] init];
				
				CLLocationCoordinate2D location;
				location.latitude = startLat + i*latitudeStep;
				location.longitude = startLong + j*longitudeStep;
				newLocation.location = location;
				
				newLocation.radius = TEST_RADIUS;
				
				newLocation.geofenceName = [NSString stringWithFormat:@"Location %i.%i", i, j];
				
				[places addObject:newLocation];
			}
		}
        success(places);
    }
}

+ (void)getGoogleSearchResultsForUser:(NSString *)userId atLocation:(CLLocationCoordinate2D)location withName:(NSString *)name withType:(NSString *)type success:(void (^)(NSArray *))success failure:(void (^)(void))failure
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:[NSString stringWithFormat:@"%f",location.latitude] forKey:@"latitude"];
	[dictionary setObject:[NSString stringWithFormat:@"%f",location.longitude] forKey:@"longitude"];
	
	[dictionary setObject:name ? name : @"" forKey:@"name"];
	
	[dictionary setObject:type ? type : @"" forKey:@"type"];
	if (!userId)
	{
		// Should never happen but if it does just break out
		return;
	}
	[ServiceAdapter _callServiceWithPath:[NSString stringWithFormat:@"google_locations/%@.json",userId] httpMethod:@"POST" postPrefixString:@"location_google=" dataObj:dictionary success:^(id results)
	 {
		 // Here we must build the Geofence objects from the returned dictionary
		 NSMutableArray *resultsArray = [NSMutableArray array];
		 for (NSDictionary *resultDictionary in results)
		 {
			 
			 RadiiResultDTO *result = [[RadiiResultDTO alloc] init];
			 result.businessTitle = [resultDictionary objectForKey:BUSINESS_TITLE_KEY];
			 
			 NSNumber *rating = [resultDictionary objectForKey:RATING_KEY];
			 result.rating = rating ? [rating floatValue] : 0;
			 
			 NSString *peopleCount = [resultDictionary objectForKey:PEOPLE_COUNT_KEY];
			 result.peopleCount = peopleCount ? [peopleCount floatValue] : 0;
			 
			 NSString *description = [resultDictionary objectForKey:DESCRIPTION_KEY];
			 result.details = description;
			 
			 CLLocationCoordinate2D location;
			 NSNumber *longitude = [resultDictionary objectForKey:@"longitude"];
			 location.longitude = [longitude floatValue];
			 
			 NSNumber *latitude = [resultDictionary objectForKey:@"latitude"];
			 location.latitude = [latitude floatValue];
			 result.searchLocation = location;
			 
			 [resultsArray addObject:result];
		 }
		 
		 success(resultsArray);
	 }];
}

#pragma mark -
#pragma mark Private Methods

+ (void)_callServiceWithPath:(NSString *)path
				  httpMethod:(NSString *)method
			postPrefixString:(NSString *)prefix
					 dataObj:(id)dataObj
					 success:(void (^)(id))success
{
	
    // Create JSON string
    NSError* error = nil;
    id json = [NSJSONSerialization dataWithJSONObject:dataObj
                                              options:kNilOptions error:&error];
    if (error != nil) {
        NSLog(@"SeviceAdapter.callService: error encoding JSON: %@", error);
        return;
    }
    
    // Construct URL
    NSArray *urlComponentArray = [[NSArray alloc] initWithObjects:BASE_URL, @"/", path, nil];
    NSURL *url = [NSURL URLWithString:[urlComponentArray componentsJoinedByString:@""]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // Construct post data
    [request setHTTPMethod:method];
    if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
		
        NSString *dataStr = [NSString stringWithFormat:@"%@%@",prefix,[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
		
        // Do URL encoding
        // see: http://stackoverflow.com/questions/6822473/correct-bridging-for-arc for ARC/bridge handling
        // http://www.raywenderlich.com/5773/beginning-arc-in-ios-5-tutorial-part-2
		
        
        NSString *encodedStr = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
																						 NULL,
																						 (__bridge CFStringRef)dataStr,
																						 NULL,
																						 CFSTR("!*'();:@&=+$,/?%#[]"),
																						 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
		
        // Set the HTTP Body
        [request setHTTPBody:[dataStr dataUsingEncoding:NSUTF8StringEncoding]];
        NSLog(@"ServiceAdapter.callService: body=%@", dataStr);
    }
    
    NSLog(@"ServiceAdapter.callService: Making request=%@", request);
    
    // Make request to server    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
		//        NSLog(@"ServiceAdapter.callService: Received type=%@, response=%@", [JSON class], JSON);
        success(JSON);
    } failure:^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON ) {
        NSString *errorMsg = [NSString stringWithFormat:@"ServiceAdapter.callService error: %@", error];
        NSLog(@"%@",errorMsg);
        //[errFuncs callWithErrorCode:@"DefaultError" errorMessage:errorMsg];
    }];
    [operation start];
    
}


#pragma mark -
#pragma mark Testing methods

// Just for testing
+ (void)testService
{
    NSLog(@"----------- TEST SERVICE --------");
    
    NSMutableDictionary *attr1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Age", @"key", @"25-34", @"attributeCategories", @"0.7", @"likelihood", nil];
    NSMutableDictionary *attr2 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Gender", @"key", @"Male", @"attributeCategories", @"0.9", @"likelihood", nil];
    
    NSMutableArray *profile = [[NSMutableArray alloc] initWithObjects:attr1,attr2, nil];
    
    NSString *userId = @"78782190374";
    
    [ServiceAdapter uploadUserProfile:profile forUser:userId success:^(id resp) {
        NSLog(@"testService: uploadUserProfile, resp:%@", resp);
		
        CLLocation *currentPoint = [[CLLocation alloc] initWithLatitude:23 longitude:121];
        [ServiceAdapter updateCurrentLocationForUser:userId location:currentPoint success:^(id resp) {
            NSLog(@"testService: updateCurrentLocation, resp=%@", resp);
            
            NSMutableArray *places = [[NSMutableArray alloc] init];
            QLPlace *place = [[QLPlace alloc] init];
            QLGeoFenceCircle *circle = [[QLGeoFenceCircle alloc] init];
            circle.latitude = 23.776074;
            circle.longitude = 122.394304;
            circle.radius = 10;
            place.geoFence = circle;
            place.name = @"poi1";
            [places addObject:place];
            
            place = [[QLPlace alloc] init];
            circle = [[QLGeoFenceCircle alloc] init];
            circle.latitude = 22;
            circle.longitude = 120;
            circle.radius = 10;
            place.geoFence = circle;
            place.name = @"poi2";
            [places addObject:place];
            
            [ServiceAdapter uploadPointsOfInterest:places forUser:userId success:^(id resp) {
                NSLog(@"testService: uploadPointsOfInterest, resp=%@", resp);
                
                
                [ServiceAdapter getGeofencesForUser:userId atLocation:currentPoint radius:5.0 success:^(id resp) {
                    NSLog(@"testService: getGeofencesForUser: %@", resp);
                }];
            }];
        }];
        
		
    }];
	
    //[ServiceAdapter getAllUsersWithSuccess:^(id resp) {
    //    NSLog(@"testService: getAllUsersWithSuccess, resp:%@", resp);
    //}];
	
    
}

+ (void)getAllUsersWithSuccess:(void (^)(id))success
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [ServiceAdapter _callServiceWithPath:@"users.json" httpMethod:@"GET" postPrefixString: @"" dataObj:d success:success];
}



@end
