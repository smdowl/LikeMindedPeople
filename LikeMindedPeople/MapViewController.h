//
//  MapViewController.h
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchBarPanelDelegate.h"
#import "GoogleLocalConnection.h"

@class DataModel, SearchBarPanel, SearchView;
@interface MapViewController : UIViewController <SearchBarPanelDelegate, GoogleLocalConnectionDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, MKMapViewDelegate>
{	
	MKMapView *_mapView;
	SearchView *_searchView;
	
	UIView *_searchingView; // A view to show the phone is busy
	UIActivityIndicatorView *_indicatorView;
	
	UIButton *_resizeButton;
	UIButton *_keyboardCancelButton;
	BOOL _isFullScreen;
	
	GoogleLocalConnection *_searchConnection;
	NSArray *_searchResults;
	
	MKUserLocation *_userLocation;
	
	// Zero alpha views to pick up swipe gestures and animate in sidebars
	UIView *_slideInLeft;
	UIView *_slideInRight;
	
	UIView *_leftCoveringView;
	UIView *_rightCoveringView;
	
	// The button that will be use to remove the slide over view
	UIButton *_slideInCancelButton;
}

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet SearchView *searchView;

@property (nonatomic, strong) IBOutlet UIView *searchingView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) IBOutlet UIButton *resizeButton;
@property (nonatomic, strong) IBOutlet UIButton *keyboardCancelButton;

@property (nonatomic, strong) IBOutlet UIView *slideInLeft;
@property (nonatomic, strong) IBOutlet UIView *slideInRight;

- (IBAction)toggleFullScreen:(id)sender;

- (IBAction)debug:(id)sender;

@end
