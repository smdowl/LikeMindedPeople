//
//  ServerKeys.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef LikeMindedPeople_ServerKeys_h
#define LikeMindedPeople_ServerKeys_h

//#define BASE_URL @"http://radiiapp.co"
#define BASE_URL @"http://radii.herokuapp.com"

// URL used for testing locally
//#define BASE_URL @"http://0.0.0.0:3000"

// Keys for creating RadiiResultDTOs

#define BUSINESS_TITLE_KEY @"name"
#define DESCRIPTION_KEY @"vicinity"
#define RATING_KEY @"rating"
#define PEOPLE_COUNT_KEY @"peopleCount"

// Keys for creating GeofenceLocations

#define GEOFENCE_NAME @"name"
#define LATITUDE_KEY @"latitude"
#define LONGITUDE_KEY @"longitude"
#define RADIUS_KEY @"radius"

#endif
