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

@class DataModel, SearchBarPanel, SearchView, SideBar, GeofenceLocation;
@interface MapViewController : UIViewController <SearchBarPanelDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate>
{	
	MKMapView *_mapView;
	SearchView *_searchView;
	
	UIView *_searchingView; // A view to show the phone is busy
	UIActivityIndicatorView *_indicatorView;
	
	UIButton *_resizeButton;
	UIButton *_keyboardCancelButton;
	BOOL _isFullScreen;
	
	NSArray *_searchResults;
	
	MKUserLocation *_userLocation;
	
	// Zero alpha views to pick up swipe gestures and animate in sidebars
	UIView *_slideInLeft;
	UIView *_slideInRight;
	
	SideBar *_leftSideBar;
	SideBar *_rightSideBar;
	
	GeofenceLocation *_refreshLocation;
	
	// The button that will be use to remove the slide over view
	UIButton *_slideInCancelButton;
	UIView *_locationDisabledView;
		
	// Test variables
	BOOL _showingGeofences;
}

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet SearchView *searchView;

@property (nonatomic, strong) IBOutlet UIView *searchingView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) IBOutlet UIButton *resizeButton;
@property (nonatomic, strong) IBOutlet UIButton *keyboardCancelButton;

@property (nonatomic, strong) IBOutlet UIView *slideInLeft;
@property (nonatomic, strong) IBOutlet UIView *slideInRight;

@property (nonatomic, strong) IBOutlet UIView *locationDisabledView;

- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)enableLocationServices;

// Test methods
- (IBAction)debug:(id)sender;
- (IBAction)printCurrentCenter;
- (IBAction)currentLocation;
- (IBAction)displayGeofences;

@end
