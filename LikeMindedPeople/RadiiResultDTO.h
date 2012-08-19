//
//  RadiiResultDTO.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

typedef enum 
{
	bar,
	cafe,
	club,
	food,
	other
} ResultType;

@interface RadiiResultDTO : NSObject <MKAnnotation>
{
	NSString *_businessTitle;
	NSString *_details;
	ResultType _type;
	
	CGFloat _rating;
	NSUInteger _peopleCount;
	NSArray *_relatedInterests;
	
	CLLocationCoordinate2D _searchLocation;
	
	NSUInteger _historicalPeopleCount;
}

@property (nonatomic, strong) NSString *businessTitle;
@property (nonatomic, strong) NSString *details;
@property (nonatomic) ResultType type;

@property (nonatomic) CGFloat rating;
@property (nonatomic) NSUInteger peopleCount;
@property (nonatomic, strong) NSArray *relatedInterests;

@property (nonatomic) CLLocationCoordinate2D searchLocation;


@end
