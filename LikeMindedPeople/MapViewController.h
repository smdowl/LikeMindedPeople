//
//  MapViewController.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "SearchBarPanelDelegate.h"
#import "GoogleLocalConnection.h"

@class DataModel, SearchBarPanel, SearchView;
@interface MapViewController : UIViewController <SearchBarPanelDelegate, GoogleLocalConnectionDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, MKMapViewDelegate>
{	
	MKMapView *_mapView;
	SearchView *_searchView;
	
	UIButton *_resizeButton;
	UIButton *_keyboardCancelButton;
	BOOL _isFullScreen;
	
	GoogleLocalConnection *_searchConnection;
	NSArray *_searchResults;
	
	MKUserLocation *_userLocation;
}

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet SearchView *searchView;

@property (nonatomic, strong) IBOutlet UIButton *resizeButton;
@property (nonatomic, strong) IBOutlet UIButton *keyboardCancelButton;

- (IBAction)toggleFullScreen:(id)sender;

- (IBAction)debug:(id)sender;

@end
