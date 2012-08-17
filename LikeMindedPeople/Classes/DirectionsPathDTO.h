//
//  DirectionsPathDTO.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface DirectionsPathDTO : NSObject <MKOverlay>
{
	NSArray *_latLongPointValues;	// The path in lat long
	CGPathRef _mapKitPath;	// The path in map kit coordinates
}

@property (nonatomic) CGPathRef mapKitPath;

- (id)initWithPath:(NSArray *)latLongPointValues;

@end
