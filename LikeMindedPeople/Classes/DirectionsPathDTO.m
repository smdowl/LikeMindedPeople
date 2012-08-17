//
//  DirectionsPathDTO.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectionsPathDTO.h"

@implementation DirectionsPathDTO
@synthesize mapKitPath = _mapKitPath;

- (id)initWithPath:(NSArray *)latLongPointValues
{
	self = [super init];
	
	if (self)
	{
		_latLongPointValues = latLongPointValues;
		
		CGMutablePathRef path = CGPathCreateMutable();
		for (NSValue *pointValue in latLongPointValues)
		{
			CGPoint point = pointValue.CGPointValue;
			
			CLLocationCoordinate2D coord;
			coord.latitude = point.x;
			coord.longitude = point.y;
			
			MKMapPoint origin = MKMapPointForCoordinate(coord);
			
			if (CGPathIsEmpty(path))
				CGPathMoveToPoint(path, nil, origin.x, origin.y);
			else
				CGPathAddLineToPoint(path, nil, origin.x, origin.y);
		}
		_mapKitPath = CGPathCreateCopy(path);
	}
	
	return self;
}

- (CLLocationCoordinate2D)coordinate
{
	CGRect boundingRect = CGPathGetBoundingBox(_mapKitPath);
	CLLocationCoordinate2D coordinate;
	coordinate.longitude = CGRectGetMidX(boundingRect);
	coordinate.latitude = CGRectGetMidY(boundingRect);
	
	return coordinate;
}

- (MKMapRect)boundingMapRect
{
	CGRect boundingRect = CGPathGetBoundingBox(_mapKitPath);
	MKMapRect boundingMapRect = MKMapRectMake(boundingRect.origin.x, boundingRect.origin.y, boundingRect.size.width, boundingRect.size.height);
	return boundingMapRect;
}

@end
