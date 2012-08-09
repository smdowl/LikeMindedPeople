//
//  GeofenceRegion.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeofenceRegion.h"

@implementation GeofenceRegion

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context
{
	MKMapRect overlayRect = [self.overlay boundingMapRect];
	CGRect visibleRect = [self rectForMapRect:overlayRect];
	
	CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
	CGContextFillRect(context,visibleRect);
}

@end
