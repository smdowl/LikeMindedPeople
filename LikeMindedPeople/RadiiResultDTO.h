//
//  RadiiResultDTO.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class GeofenceLocation;
@interface RadiiResultDTO : NSObject <MKAnnotation>
{
	NSString *_businessTitle;
	NSString *_description;
	
	CGFloat _rating;
	NSUInteger _peopleCount;
	NSArray *_relatedInterests;
	
	GeofenceLocation *_geofence;
	CLLocationCoordinate2D _searchLocation;
}

@property (nonatomic,strong) NSString *businessTitle;
@property (nonatomic,strong) NSString *description;

@property (nonatomic) CGFloat rating;
@property (nonatomic) NSUInteger peopleCount;
@property (nonatomic, strong) NSArray *relatedInterests;

@property (nonatomic,strong) GeofenceLocation *geofence;
@property (nonatomic) CLLocationCoordinate2D searchLocation;


@end
