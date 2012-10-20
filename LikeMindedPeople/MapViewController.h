//
//  MapViewController.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "SearchView.h"

typedef enum
{
    fullScreen = 0,
    halfScreen = 1,
    mapHidden = 2
} MapVisible;

@class DataModel, SearchBarPanel, SearchView, SideBar, GeofenceLocation, DetailViewController;
@interface MapViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, SearchViewDelegate>
{	
	MKMapView *_mapView;
	SearchView *_searchView;
	
	UIView *_searchingView; // A view to show the phone is busy
	UIActivityIndicatorView *_indicatorView;
	
	UIButton *_keyboardCancelButton;

	BOOL _transitioningToFullScreen;	// Used to refresh the annotations because they seem to disapear
	
	NSArray *_searchResults;
	NSMutableArray *_storedResults;		// An array to be used to temporarily store results that have been removed when presenting directions
	
	MKUserLocation *_userLocation;
	
	// Zero alpha views to pick up swipe gestures and animate in sidebars
	UIView *_slideInLeft;
	UIView *_slideInRight;
	
	SideBar *_leftSideBar;
	SideBar *_rightSideBar;
	
	GeofenceLocation *_refreshLocation;	// The geofence that, if exited, will begin refreshing the geofences
	
	// The button that will be use to remove the slide over view
	UIButton *_slideInCancelButton;
	UIView *_locationDisabledView;

	BOOL _locationSet;
	
	NSTimer *_detailViewTimer;	// A timer to be started when an annotation is deselected and which will be invalidated when a new pin is selected. This means the details view can stay visible but without a ui glitch
	
	// Test variables
	BOOL _showingGeofences;
	
	MKPolyline *_directionsLine;
	
	UIView *_debugPanel;
	CLLocationManager *_locationManager;
	
	BOOL _askedForPermission;
    
    MapVisible _mapVisible;
    
    DetailViewController *_detailView;
}

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet SearchView *searchView;

@property (nonatomic, strong) IBOutlet UIView *searchingView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) IBOutlet UIButton *keyboardCancelButton;

@property (nonatomic, strong) IBOutlet UIView *slideInLeft;
@property (nonatomic, strong) IBOutlet UIView *slideInRight;

@property (nonatomic, strong) IBOutlet UIView *locationDisabledView;
@property (nonatomic, strong) IBOutlet UIView *debugPanel;

@property (nonatomic) MapVisible mapVisible;

- (IBAction)enableLocationServices;

// Test methods
- (IBAction)debug:(id)sender;
- (IBAction)printCurrentCenter;
- (IBAction)currentLocation;
- (IBAction)displayGeofences;

- (IBAction)refreshLocation;
- (IBAction)showDetailView;

@end
