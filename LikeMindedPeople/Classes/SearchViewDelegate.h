//
//  SearchViewDelegate.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 8/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RadiiResultDTO;
@protocol SearchViewDelegate <NSObject>

- (void)checkLayout;	// Called when the SearchView's size has changed so that an UI adjustments can be made

- (void)beginSearchForPlacesWithName:(NSString *)name type:(NSString *)type;

- (void)cancelSearch;

- (void)deselectPin;

- (void)getDirectionsToLocation:(RadiiResultDTO *)location;

@end
