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
#import "LocationDetailsDTO.h"
#import "CategoryDTO.h"

#define DEBUG_MODE 0
#define FAKE_SEARCH 0

#define SAN_FRAN_LATITUDE_MIN 37.755787
#define SAN_FRAN_LATITUDE_MAX 37.797306

#define SAN_FRAN_LONGITUDE_MIN -122.430439
#define SAN_FRAN_LONGITUDE_MAX -122.378769

#define TEST_GRID_WIDTH 10

#define TEST_RADIUS 25

#define GOOGLE_DIRECTIONS_URL @"http://maps.googleapis.com/maps/api/directions/json?"

@interface ServiceAdapter()
+ (void)_callServiceWithPath:(NSString *)path
				  httpMethod:(NSString *)method
			postPrefixString:(NSString *)prefix
					 dataObj:(id)dataObj
					 success:(void (^)(id))success
					 failure:(void (^)(NSError *))failure;
@end

@implementation ServiceAdapter

+ (void)uploadUserProfile:(NSDictionary *)profile userDetails:(NSDictionary *)userDetails success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        
    [d setObject:userDetails forKey:@"user"];
    [d setObject:profile forKey:@"profile"];
	
    [ServiceAdapter _callServiceWithPath:@"users.json" httpMethod:@"POST" postPrefixString:@"user_profile=" dataObj:d success:success failure:failure];
}

+ (void)updateCurrentLocationForUser:(NSString *)userId location:(CLLocation *)location success:(void (^)(id))success failure:(void (^)(NSError *))failure 
{
	NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *dloc = [[NSMutableDictionary alloc] init];
    [dloc setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"lattitude"];
    [dloc setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
    [dloc setObject:@"10" forKey:@"radius"];
    [d setObject:dloc forKey:@"location"];
    
    [d setObject:userId forKey:@"api_id"];
    #warning TODO
    // TODO: Get radius somehow
    
    
    [ServiceAdapter _callServiceWithPath:@"update_location.json" httpMethod:@"POST" postPrefixString:@"location=" dataObj:dloc success:success failure:failure];
}


// pointsOfInterest: array of QLPlace
+ (void)uploadPointsOfInterest:(NSArray *)pointsOfInterest forUser:(NSString *)userId success:(void (^)(id))success failure:(void (^)(NSError *))failure 
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
	[ds setValue:userId forKey:@"api_id"];
    
    [ServiceAdapter _callServiceWithPath:[NSString stringWithFormat:@"users.json"] httpMethod:@"POST" postPrefixString:@"pois=" dataObj:ds success:success failure:failure];
}

+ (void)getGeofencesForUser:(NSString *)userId atLocation:(CLLocation *)location radius:(CGFloat)radius success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure 
{    
    // Make "YES" for testing, "NO" to use servers.
#if !DEBUG_MODE
	NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
	[d setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"latitude"];
	[d setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
	// Filter in miles
	[d setObject:[NSString stringWithFormat:@"%f",radius]  forKey:@"filter"];
	[d setObject:userId ? userId : @"" forKey:@"api_id"];
	
	[ServiceAdapter _callServiceWithPath:[NSString stringWithFormat:@"filter_locations"] httpMethod:@"POST" postPrefixString:@"location_filter=" dataObj:d success:^(NSArray *results)
	 {
		 NSMutableArray *geofences = [NSMutableArray array];
		 for (NSDictionary *geofenceDictionary in results)
		 {
			 GeofenceLocation *geofence = [[GeofenceLocation alloc] init];
			 geofence.geofenceName = [geofenceDictionary objectForKey:GEOFENCE_NAME];
			 
			 CLLocationCoordinate2D location;
			 location.latitude = [[geofenceDictionary objectForKey:LATITUDE_KEY] floatValue];
			 location.longitude = [[geofenceDictionary objectForKey:LONGITUDE_KEY] floatValue];
			 geofence.location = location;
			 
			 geofence.radius = [[geofenceDictionary objectForKey:RADIUS_KEY] floatValue];
			 [geofences addObject:geofence];
		 }
	 
	 success(geofences);
	 } 
								 failure:failure];
#else
		
        NSMutableArray *places = [NSMutableArray array];
		
		CLLocationCoordinate2D coordinate = location.coordinate;
		
		CGFloat approximateLatitudeChange = radius / 111000;
		CGFloat approximateLongitudeChange = radius / (111000 * cosf(coordinate.latitude));
		
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
#endif
}

+ (void)getLocationDetails:(RadiiResultDTO *)location userId:(NSString *)userId success:(void (^)(LocationDetailsDTO *))success failure:(void (^)(NSError *))failure 
{
	NSMutableDictionary *locationDictionary = [NSMutableDictionary dictionary];
	[locationDictionary setValue:userId forKey:@"api_id"];
	[locationDictionary setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"latitude"];
	[locationDictionary setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
	[locationDictionary setObject:location.businessTitle forKey:@"query"];
	
	[ServiceAdapter _callServiceWithPath:[NSString stringWithFormat:@"venue_details"] httpMethod:@"POST" postPrefixString:@"venue_query=" dataObj:locationDictionary success:^(NSDictionary *result)
	 {
		 LocationDetailsDTO *details = [[LocationDetailsDTO alloc] init];
		 details.name = [result objectForKey:@"name"];
		 details.description = [result objectForKey:@"description"];
         
         details.currentPeopleCount = [[result objectForKey:@"people_now_count"] unsignedIntValue];
         details.rating = [[result objectForKey:@"rating"] floatValue];
		 
         details.address = [result objectForKey:@"address"];
         
		 NSMutableArray *categories = [NSMutableArray array];
		 for (NSDictionary *category in [result objectForKey:@"categories"])
		 {
			 CategoryDTO *newCategory = [[CategoryDTO alloc] init];
			 newCategory.name = [category objectForKey:@"name"];
			 
			 NSMutableArray *parentCategories = [NSMutableArray array];
			 for (NSString *parentName in [category objectForKey:@"parents"])
			 {
				 [parentCategories addObject:parentName];
			 }
			 newCategory.parentCategories = parentCategories;
			 
			 [categories addObject:newCategory];
		 }
		 details.categories = categories;
		 
		 NSString *menuString = [result objectForKey:@"menu"];
		 details.menuURL = menuString;
		 
         
         
		 success(details);
	 }
								 failure:failure];
}

+ (void)enterGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success failure:(void (^)(NSError *))failure 
{
	NSMutableDictionary *geofenceDictionary = [NSMutableDictionary dictionary];
	[geofenceDictionary setValue:userId forKey:@"api_id"];
	[geofenceDictionary setValue:[NSString stringWithFormat:@"%f",geofence.location.latitude] forKey:@"latitude"];
	[geofenceDictionary setValue:[NSString stringWithFormat:@"%f",geofence.location.longitude] forKey:@"longitude"];
	[geofenceDictionary setValue:geofence.geofenceName forKey:@"name"];
	
	[ServiceAdapter _callServiceWithPath:@"visits.json" httpMethod:@"POST" postPrefixString:@"visit=" dataObj:geofenceDictionary success:^(id result)
	 {
		 for (NSDictionary *resultDictionary in result)
		 {
//			 BOOL wasSuccessful = [[resultDictionary objectForKey:@"success"] boolValue];
			 success(result);
		 }
	 } 
								 failure:failure];
}

+ (void)exitGeofence:(GeofenceLocation *)geofence userId:(NSString *)userId success:(void (^)(id))success failure:(void (^)(NSError *))failure 
{
	NSMutableDictionary *geofenceDictionary = [NSMutableDictionary dictionary];
	[geofenceDictionary setValue:userId forKey:@"api_id"];
	[geofenceDictionary setValue:[NSString stringWithFormat:@"%f",geofence.location.latitude] forKey:@"latitude"];
	[geofenceDictionary setValue:[NSString stringWithFormat:@"%f",geofence.location.longitude] forKey:@"longitude"];
	[geofenceDictionary setValue:geofence.geofenceName forKey:@"name"];
	[geofenceDictionary setValue:@"00:10:30" forKey:@"stay"];

	[ServiceAdapter _callServiceWithPath:@"exit.json" httpMethod:@"POST" postPrefixString:@"exit=" dataObj:geofenceDictionary success:^(id result)
	 {
		 for (NSDictionary *resultDictionary in result)
		 {
//			 BOOL wasSuccessful = [[resultDictionary objectForKey:@"success"] boolValue];
			 success(result);
		 }
	 }
								 failure:failure];
}

+ (void)getFourSquareSearchResultsForUser:(NSString *)userId atLocation:(CLLocationCoordinate2D)location withQuery:(NSString *)query type:(NSString *)type success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setValue:userId forKey:@"api_id"];
	[dictionary setObject:[NSString stringWithFormat:@"%f",location.latitude] forKey:@"latitude"];
	[dictionary setObject:[NSString stringWithFormat:@"%f",location.longitude] forKey:@"longitude"];
	[dictionary setValue:[NSNumber numberWithInt:5] forKey:@"limit"];
//	[dictionary setObject:name ? name : @"" forKey:@"name"];
//	
//	[dictionary setObject:type ? type : @"" forKey:@"type"];
	
    if (query)
        [dictionary setValue:query forKey:@"query"];

    if (type)
        [dictionary setValue:type forKey:@"section"];
	
	if (!userId)
	{
		// Should never happen but if it does just break out
		return;
	}
    
	[ServiceAdapter _callServiceWithPath:@"foursquare_venues.json" httpMethod:@"POST" postPrefixString:@"foursquare_query=" dataObj:dictionary success:^(id results)
	 {
		 // Here we must build the Geofence objects from the returned dictionary
		 NSMutableArray *resultsArray = [NSMutableArray array];
		 for (NSDictionary *resultDictionary in results)
		 {
			 
			 RadiiResultDTO *result = [[RadiiResultDTO alloc] init];
             result.businessId = [NSNumber numberWithInt:[[resultDictionary objectForKey:@"id"] intValue]];
			 result.businessTitle = [resultDictionary objectForKey:BUSINESS_TITLE_KEY];
             
			 NSString *peopleHistoryCount = [resultDictionary objectForKey:PEOPLE_HISTORY_COUNT_KEY];
			 result.peopleHistoryCount = peopleHistoryCount ? [peopleHistoryCount intValue] : 0;
             
             NSString *peopleNowCount = [resultDictionary objectForKey:PEOPLE_NOW_COUNT_KEY];
			 result.peopleNowCount = peopleNowCount ? [peopleNowCount intValue] : 0;
             
			 NSString *description = [resultDictionary objectForKey:DESCRIPTION_KEY];
			 result.details = description;
             
             NSNumber *rating = [resultDictionary objectForKey:RATING_KEY];
			 result.rating = rating ? [rating floatValue] : 0;
             
             
#if FAKE_SEARCH
             // If we want nice results then flip a coin to decide for each result if we want to fake it
             BOOL randomize = arc4random() % 2;
             
             // Create a random number of visitors if there were none
             if (!result.peopleHistoryCount && randomize)
             {
                 result.peopleHistoryCount = arc4random() % 25;
             }

             // Create a random rating
             if (!result.rating && result.peopleHistoryCount && randomize)
             {
                 result.rating = (float)(arc4random() % 100) / 100;
             }
#endif
             
			 CLLocationCoordinate2D location;
			 NSNumber *longitude = [resultDictionary objectForKey:@"longitude"];
			 location.longitude = [longitude floatValue];
			 
			 NSNumber *latitude = [resultDictionary objectForKey:@"latitude"];
			 location.latitude = [latitude floatValue];
			 result.searchLocation = location;
			 
			 result.type = other;
			 
			 for (NSDictionary *category in [resultDictionary objectForKey:@"categories"])
			 {
				 NSString *categoryName = [category objectForKey:@"name"];
//				 NSLog(@"%@", categoryName);
				 if ([categoryName rangeOfString:@"Bar"].length || [categoryName isEqualToString:@"Pub"] || [categoryName isEqualToString:@"Brewery"])
				 {
					 result.type = bar;
					 break;
				 }
				 else if ([categoryName isEqualToString:@"Café"] || [categoryName isEqualToString:@"Coffee Shop"]|| [categoryName isEqualToString:@"Bakery"])
				 {
					 result.type = cafe;
					 break;
				 }
				 else if ([categoryName isEqualToString:@"Nightclub"] || [categoryName isEqualToString:@"Lounge"])
				 {
					 result.type = club;
					 break;
				 }
				 else if ([categoryName rangeOfString:@"Restaurant"].length || [categoryName isEqualToString:@"Diner"] || 
						  [categoryName rangeOfString:@"Sandwich"].length || [categoryName rangeOfString:@"Breakfast"].length)
				 {
					 result.type = food;
					 break;
				 }
			 }
			 
			 [resultsArray addObject:result];
		 }
		 
		 [resultsArray sortUsingComparator:^(RadiiResultDTO *r1, RadiiResultDTO *r2)
		  {
			  if (r1.rating != r2.rating)
				  return r1.rating < r2.rating;
			  else
				  return r1.peopleHistoryCount < r2.peopleHistoryCount;
		  }];
		 
		 success(resultsArray);
	 }
								 failure:failure];    
}

+ (void)ratePlace:(RadiiResultDTO *)place user:(NSString *)userId up:(BOOL)up
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setValue:userId forKey:@"api_id"];
	[dictionary setObject:[NSString stringWithFormat:@"%@",place.businessId] forKey:@"business_id"];
	[dictionary setValue:[NSNumber numberWithBool:up] forKey:@"rated_up"];
    
    [ServiceAdapter _callServiceWithPath:@"rate" httpMethod:@"POST" postPrefixString:@"rate_query=" dataObj:dictionary success:^(id results)
	 {
             
     }
                                 failure:^(NSError *err)
     {
         NSLog(@"%@", err);
     }];
}

+ (void)getDirectionsFromLocation:(CLLocationCoordinate2D)from toLocation:(CLLocationCoordinate2D)to onSuccess:(void(^)(NSDictionary *))success failure:(void (^)(NSError *))failure
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@origin=%f,%f&destination=%f,%f&sensor=true&mode=walking",GOOGLE_DIRECTIONS_URL,from.latitude,from.longitude,to.latitude,to.longitude]];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
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
#pragma mark Private Methods

+ (void)_callServiceWithPath:(NSString *)path
				  httpMethod:(NSString *)method
			postPrefixString:(NSString *)prefix
					 dataObj:(id)dataObj
					 success:(void (^)(id))success
					 failure:(void (^)(NSError *))failure
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
    AFJSONRequestOperation *operation = 
	[AFJSONRequestOperation JSONRequestOperationWithRequest:request 
													success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
														//        NSLog(@"ServiceAdapter.callService: Received type=%@, response=%@", [JSON class], JSON);
														if (JSON)
															success(JSON);
														else
															failure(error);
														
													} 
													failure:^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON ) {
														NSString *errorMsg = [NSString stringWithFormat:@"ServiceAdapter.callService error: %@", error];
														NSLog(@"ERROR: %@",[JSON objectForKey:@"message"]);
														failure(error);
														//[errFuncs callWithErrorCode:@"DefaultError" errorMessage:errorMsg];
													}];
//    [RD_PROVIDER.operationQueue addOperation:operation];
    [operation start];
    
}

+ (void)getAllUsersWithSuccess:(void (^)(id))success
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [ServiceAdapter _callServiceWithPath:@"users.json" httpMethod:@"GET" postPrefixString: @"" dataObj:d success:success failure:^(NSError *error)
	 {
		 
	 }];
}

@end
