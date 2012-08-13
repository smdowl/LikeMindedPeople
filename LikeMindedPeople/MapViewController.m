//
//  MapViewController.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import "DataModel.h"
#import "ServiceAdapter.h"
#import "SearchView.h"
#import "TDBadgedCell.h"
#import "SearchBar.h"
#import "RAdiiResultDTO.h"
#import "DetailView.h"
#import "SideBar.h"
#import "GeofenceRegion.h"

#define RESIZE_BUTTTON_PADDING 5
#define MAX_BUTTON_ALPHA 0.4

#define SIDE_BAR_WIDTH 180

#define DEBUG_BUTTONS 1

@interface MapViewController ()

- (void)_removeAllNonUserAnnotations;
- (void)_animateMap:(BOOL)fullScreen;
- (void)_hideKeyboard;

- (void)_inFromLeft:(UIPanGestureRecognizer *)recognizer;
- (void)_inFromRight:(UIPanGestureRecognizer *)recognizer;

- (void)_setMapVisible:(BOOL)visible;

@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize searchView = _searchView;

@synthesize searchingView = _searchingView;
@synthesize indicatorView = _indicatorView;

@synthesize resizeButton = _resizeButton;
@synthesize keyboardCancelButton = _keyboardCancelButton;

@synthesize slideInLeft = _slideInLeft;
@synthesize slideInRight = _slideInRight;

@synthesize locationDisabledView = _locationDisabledView;
@synthesize debugPanel = _debugPanel;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[[NSBundle mainBundle] loadNibNamed:@"SearchView" owner:self options:nil];
	
	// Fit the frame in the gap between the map and the bottom of the view with the bar panel overlapping the map
	CGRect searchViewFrame = _searchView.frame;
	searchViewFrame.origin.y = CGRectGetMaxY(_mapView.frame) - _searchView.searchBarPanel.frame.size.height;
	searchViewFrame.size.height = self.view.frame.size.height - searchViewFrame.origin.y;
	_searchView.frame = searchViewFrame;
	
	CGRect resizeButtonFrame = _resizeButton.frame;
	resizeButtonFrame.origin.y -= _searchView.searchBarPanel.frame.size.height;
	_resizeButton.frame = resizeButtonFrame;
	
	[self.view addSubview:_searchView];
	_searchView.delegate = self;
	
	[_resizeButton setImage:[UIImage imageNamed:@"fullscreen.png"] forState:UIControlStateNormal];
	[_resizeButton setImage:[UIImage imageNamed:@"fullscreenglow.png"] forState:UIControlStateHighlighted];
	
	UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
	
	// Need to set us as the delgate because of the map views own gesture reconizers
	pinchRecognizer.delegate = self;  
    [_mapView addGestureRecognizer:pinchRecognizer];
	_mapView.delegate = self;
	_mapView.showsUserLocation = YES;
	
	[_keyboardCancelButton addTarget:self action:@selector(_hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
	[_keyboardCancelButton removeFromSuperview];
		
	_searchView.searchResultsView.delegate = self;
	_searchView.searchResultsView.dataSource = self;
	
	// Recognizing gestures on the left side of the screen
	UIPanGestureRecognizer *leftSwipeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_inFromLeft:)];
	[_slideInLeft addGestureRecognizer:leftSwipeGestureRecognizer];
	
	// Recognizing gestures on the right side of the screen
	UIPanGestureRecognizer *rightSwipeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_inFromRight:)];
	[_slideInRight addGestureRecognizer:rightSwipeGestureRecognizer];
	
//	[_searchView.detailView.backButton addTarget:_searchView action:@selector(hideDetailView) forControlEvents:UIControlEventTouchUpInside];
	
	// TODO: Maybe take this out
	[[DataModel sharedInstance] addLocationListener:self];	
	
#if DEBUG_BUTTONS
	_debugPanel.hidden = NO;
#endif
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
		
	// Set the searchBarPanel to recieve keyboard notifications
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];

	DataModel *dataModel = [DataModel sharedInstance];
	[dataModel.coreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *connectorPermissions) {
        
    } disabled:^(NSError *err) {
		[dataModel.coreConnector enableFromViewController:self success:nil failure:nil];
    }];
	
	if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized)
	{
		[self _setMapVisible:NO];
		
		CLLocationManager *locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
	}
	else
	{
		[self _setMapVisible:YES];
	}
	
	[[DataModel sharedInstance] updateGeofenceRefreshLocation];
	
	_mapView.showsUserLocation = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	// Stop the SearchBarPanel recieving notifications
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	_mapView.showsUserLocation = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
    _mapView = nil;
	_searchView = nil;
	_resizeButton = nil;
}

#pragma mark -
#pragma mark IBOutlet Methods

- (IBAction)toggleFullScreen:(id)sender
{
	if (_isFullScreen)
	{
		_isFullScreen = NO;
		[self _animateMap:NO];
	}
	else
	{
		_isFullScreen = YES;
		[self _animateMap:YES];
	}
}

- (IBAction)enableLocationServices
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
}

#pragma mark -
#pragma mark SearchViewDelegate

- (void)checkLayout
{
	[UIView beginAnimations:nil context:nil];
	
	CGRect resizeFrame = _resizeButton.frame;
	resizeFrame.origin.y = _searchView.frame.origin.y - _resizeButton.frame.size.height;
	_resizeButton.frame = resizeFrame;
	
	[UIView commitAnimations];
}

- (void)beginSearchForPlacesWithName:(NSString *)name type:(NSString *)type
{
	if (name.length || type.length)
	{
//		[_searchConnection getGoogleObjectsWithQuery:searchText andMapRegion:[_mapView region] andNumberOfResults:20 addressesOnly:YES andReferer:@"http://WWW.radii.com"];    
		[ServiceAdapter getGoogleSearchResultsForUser:@"userId" atLocation:_mapView.centerCoordinate withName:name withType:type success:^(NSArray *results)
		 {
//			 _searchingView.hidden = YES;
//			 [_indicatorView stopAnimating];
			 
			 if ([results count] == 0)
			 {
				 [self _removeAllNonUserAnnotations];
			 }
			 else 
			 {				
				 // Replace all the annotations with new ones
				 [self _removeAllNonUserAnnotations];
				 
				 _searchResults = results;
				 
				 // Add the repackaged results as annotations
				 [_mapView addAnnotations:_searchResults];
				 
				 if (_userLocation)
				 {
					 [_mapView addAnnotation:_userLocation];
				 }
				 
				 [_searchView setData:_searchResults];
			 }
		 }
		 failure:^()
		 {
			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error finding place - Try again" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			 [alert show];
			 
			 _searchingView.hidden = YES;
			 [_indicatorView stopAnimating];
			 
			 // Deselect whatever row was selected when the error occured
			 [_searchView selectButton:-1];
		 }
		 ];
//		_searchingView.hidden = NO;
//		[_indicatorView startAnimating];
	}
	else 
	{
		[self _removeAllNonUserAnnotations];
	}
}

- (void)cancelSearch
{
	[_searchView selectButton:-1];
//	[self _removeAllNonUserAnnotations];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	if (!_locationSet)
	{
		_userLocation = userLocation;
		
		// When the view appears, home in on our location
		CLLocation *newLocation = _mapView.userLocation.location;
		
		double scalingFactor = ABS( (cos(2 * M_PI * newLocation.coordinate.latitude / 360.0) ));
		
		// Specify the amound of miles we want to see around our location
		double miles = 0.5;
		
		MKCoordinateRegion region;
		region.span.latitudeDelta = miles/69.0;
		region.span.longitudeDelta = miles/(scalingFactor * 69.0); 
		region.center = newLocation.coordinate;
		
		[_mapView setRegion:region animated:YES];
		
		_locationSet = YES;
	}
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	// TODO: trying to stop the user from disappearing. Not 100% sure if this helps
	if (_userLocation)
	{
		[_mapView addAnnotation:_userLocation];
	}
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if (view.annotation == _userLocation)
		return;
	
	RadiiResultDTO *result = (RadiiResultDTO *)view.annotation;
	
	// Move the table view if it is on screen
	[_searchView.searchResultsView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[_searchResults indexOfObject:result] inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		
	if (_isFullScreen)
	{
		[_searchView showDetailView];
	}
	
	// Update the detail view
	[_searchView.detailView setData:result];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	[_searchView.searchResultsView deselectRowAtIndexPath:[_searchView.searchResultsView indexPathForSelectedRow] animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	MKAnnotationView *annotationView;
	if ([annotation isKindOfClass:[RadiiResultDTO class]])
	{
		RadiiResultDTO *radiiResult = (RadiiResultDTO *)annotation;
		annotationView = [_mapView dequeueReusableAnnotationViewWithIdentifier:@"radiiPin"];
		
		if (!annotationView)
		{
			annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"radiiPin"];
		}
		else 
		{
			annotationView.annotation = annotation;
		}
		
		switch (radiiResult.type)
		{
			case food:
				annotationView.image = [UIImage imageNamed:@"food_pin.png"];
				break;
			case cafe:
				annotationView.image = [UIImage imageNamed:@"cafe_pin.png"];
				break;
			case bar:
				annotationView.image = [UIImage imageNamed:@"bars_pin.png"];
				break;
			case club:
				annotationView.image = [UIImage imageNamed:@"club_pin.png"];
				break;
			default:
				break;
				
		}
//		annotationView.centerOffset = CGPointMake(0,-annotationView.image.size.height);
		
		return annotationView;
	}
//	else if ([annotation isKindOfClass:[MKUserLocation class]])
	else if (annotation == _mapView.userLocation)
	{
		MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:@"mePin"];

		if (!annotationView)
		{
			annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"mePin"];
			annotationView.animatesDrop = NO;
			annotationView.canShowCallout = NO;
		}
		else 
		{
			annotationView.annotation = annotation;
		}
		
		// TODO: use the type of the result to decide on the image for the annotationView
		annotationView.image = [UIImage imageNamed:@"me_pin.png"];
	}
	
	return annotationView;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
	MKCircleView *region = [[MKCircleView alloc] initWithOverlay:overlay];
	if (overlay == _refreshLocation)
	{
		region.fillColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
		region.strokeColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8];		
		region.lineWidth = 2.0;
	}
	else
	{
		region.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.5];
		region.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:0.8];
		region.lineWidth = 1.0;
	}
	return region;
}
#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
//	_userLocation = [[MKAnnotation alloc] init];
	
	
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if (status == kCLAuthorizationStatusAuthorized)
	{
		[self _setMapVisible:YES];
		[_mapView setCenterCoordinate:[[manager location] coordinate]];
	}
}

#pragma mark -
#pragma mark UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	TDBadgedCell *cell = (TDBadgedCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (!cell)
	{
		cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];	
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.textColor = [UIColor colorWithRed:89/255 green:89/255 blue:89/255 alpha:1.0];
		cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:12];  
	}
	
	RadiiResultDTO *radiiResult = [_searchResults objectAtIndex:indexPath.row];
	
	cell.textLabel.text = radiiResult.businessTitle;
	cell.detailTextLabel.text = radiiResult.details;
	
	NSString *badgeString = [NSString stringWithFormat:@"%.0f%@",radiiResult.rating*100,@"%"];    
	
    cell.badgeString = badgeString;
    cell.badgeColor = [UIColor colorWithRed:0 green:0.6796875 blue:0.93359375 alpha:radiiResult.rating];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// Set the detail view's data. This fill in the UI
	[_searchView showDetailView];
	_searchView.detailView.data = [_searchResults objectAtIndex:indexPath.row];
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _searchResults ? _searchResults.count : 0;
}

#pragma mark -
#pragma mark PinchGestureRecognizer Methods

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{	
	switch (pinchGestureRecognizer.state)
	{
		case UIGestureRecognizerStateChanged:
			if([pinchGestureRecognizer scale] > 1 && !_isFullScreen) 
			{
				_transitioningToFullScreen = YES;
				_isFullScreen = YES;
				[self _animateMap:YES];
			}
			break;
		case UIGestureRecognizerStateEnded:
			if (_transitioningToFullScreen)
			{
				_transitioningToFullScreen = NO;
				dispatch_async(dispatch_get_main_queue(), ^()
							   {
								   NSArray *annotations = [_mapView annotations];
								   [_mapView removeAnnotations:annotations];
								   [_mapView addAnnotations:annotations];								
							   });
				_mapView.showsUserLocation = NO;
				_mapView.showsUserLocation = YES;
			}
			break;
		default:
			break;
	}
}

// Must call this so that our recognizers pinch insn't stolen by the map view
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


#pragma mark -
#pragma mark Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGSize viewSize = self.view.frame.size;
	CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	
	[UIView beginAnimations:nil context:nil];
	CGRect searchViewFrame = _searchView.frame;
	searchViewFrame.origin.y = viewSize.height - keyboardSize.height - _searchView.searchBarPanel.frame.size.height;	
	_searchView.frame = searchViewFrame;
	
	CGRect resizeButtonFrame = _resizeButton.frame;
	resizeButtonFrame.origin.y = searchViewFrame.origin.y - _resizeButton.frame.size.height;
	_resizeButton.frame = resizeButtonFrame;
	[UIView commitAnimations];
	
	[self.view insertSubview:_keyboardCancelButton belowSubview:_searchView];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	CGSize viewSize = self.view.frame.size;
	
	[UIView beginAnimations:nil context:nil];
	CGRect searchViewFrame = _searchView.frame;	
	searchViewFrame.origin.y = _isFullScreen ? viewSize.height - [_searchView panelHeight] : viewSize.height - _searchView.frame.size.height;
	_searchView.frame = searchViewFrame;
	
	CGRect resizeButtonFrame = _resizeButton.frame;
	resizeButtonFrame.origin.y = searchViewFrame.origin.y - _resizeButton.frame.size.height;
	_resizeButton.frame = resizeButtonFrame;
	[UIView commitAnimations];
	
	[_keyboardCancelButton removeFromSuperview];
}

- (void)_inFromLeft:(UIPanGestureRecognizer *)recognizer
{
	CGFloat xPosition = [recognizer translationInView:self.view].x;
	CGRect coveringFrame;
	
	UIGestureRecognizerState state = recognizer.state;
	if (state == UIGestureRecognizerStateBegan)
	{
		// Create an invisible button to cancel the overlay
		_slideInCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_slideInCancelButton.frame = self.view.bounds;
		_slideInCancelButton.backgroundColor = [UIColor darkGrayColor];
		_slideInCancelButton.alpha = 0;
		[_slideInCancelButton addTarget:self action:@selector(_outToLeft:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_slideInCancelButton];
		
		// Create the covering view
		_leftSideBar = [[SideBar alloc] initWithFrame:CGRectMake(xPosition - SIDE_BAR_WIDTH,0,SIDE_BAR_WIDTH,self.view.frame.size.height)];			
		
		UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_outToLeft:)];
		swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
		[_leftSideBar addGestureRecognizer:swipeRecognizer];
		
		[self.view addSubview:_leftSideBar];
		
	} 
	else if (state == UIGestureRecognizerStateChanged)
	{
		// Only move the view to, at most, its width
		if (xPosition <= SIDE_BAR_WIDTH)
		{
			CGFloat buttonAlpha = xPosition / SIDE_BAR_WIDTH * MAX_BUTTON_ALPHA;
			_slideInCancelButton.alpha = buttonAlpha;
			
			coveringFrame = _leftSideBar.frame;
			coveringFrame.origin.x = xPosition - SIDE_BAR_WIDTH;
			_leftSideBar.frame = coveringFrame;
		}
	} 
	else if (state == UIGestureRecognizerStateEnded)
	{
		void (^onComplete)(BOOL finished);
		CGFloat buttonAlpha;
		
		// Track the ending velocity to decide if the sidebar was "thrown" back
		CGPoint endingVelocity = [recognizer velocityInView:self.view];
		
		// If the view is at least half out, animate the rest.
		// Otherwise, animate it back out.
		if (xPosition >	SIDE_BAR_WIDTH / 4 && endingVelocity.x > 0.0)
		{
			coveringFrame = CGRectMake(0, 0, SIDE_BAR_WIDTH, self.view.frame.size.height);
			buttonAlpha = MAX_BUTTON_ALPHA;
			onComplete = ^(BOOL finished)
			{
				// Set up anything we want on the view after it has finished moving
			};
		}
		else
		{
			coveringFrame = CGRectMake(-SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH, self.view.frame.size.height);
			buttonAlpha = 0.0;
			
			onComplete = ^(BOOL finished)
			{
				[_leftSideBar removeFromSuperview];
				_leftSideBar = nil;
				
				[_slideInCancelButton removeFromSuperview];
				_slideInCancelButton = nil;
			};
		}

		// Animate for both in and out
		[UIView animateWithDuration:0.2 animations:^()
		 {
			 _leftSideBar.frame = coveringFrame;
			 _slideInCancelButton.alpha = buttonAlpha;
		 }
						 completion:onComplete];
	}
}

// Might want to do this with a swipe gestore or another pan
- (void)_outToLeft:(id)sender
{	
	[UIView animateWithDuration:0.3 animations:^()
	 {
		 _leftSideBar.frame = 	CGRectMake(-SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH, self.view.frame.size.height);;
		 _slideInCancelButton.alpha = 0.0;
	 }
					 completion:^(BOOL finished)
	 {
		 [_leftSideBar removeFromSuperview];
		 [_slideInCancelButton removeFromSuperview];
	 }];
}

- (void)_inFromRight:(UIPanGestureRecognizer *)recognizer
{
	
}

#pragma mark -
#pragma mark Private Methods

- (void)_removeAllNonUserAnnotations
{
	for (id<MKAnnotation> annotation in _mapView.annotations)
	{
		if (annotation == _userLocation)
		{
			continue;
		}
		else
		{
			[_mapView removeAnnotation:annotation];
		}
	}
	
	_searchResults = nil;
	[_searchView setData:_searchResults];
}

- (void)_animateMap:(BOOL)toFullScreen
{
	CGFloat verticalShift = toFullScreen ? _searchView.searchResultsView.frame.size.height : -_searchView.searchResultsView.frame.size.height;
	NSString *resizeButtonImageName = toFullScreen ? @"minimize.png" : @"fullscreen.png";
	NSString *resizeGlowButtonImageName = toFullScreen ? @"minimizeglow.png" : @"fullscreenglow.png";
	
	CGFloat backButtonRotation = toFullScreen ? M_PI_2 : 0;
	
	// Remove all targets from the back button
	[_searchView.detailView.backButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
	
	// Either set it to remove from screen on return to normal view
	if (toFullScreen)
	{
		[_searchView.detailView.backButton addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventTouchUpInside];
	}
	else
	{
		[_searchView.detailView.backButton addTarget:_searchView action:@selector(hideDetailView) forControlEvents:UIControlEventTouchUpInside];
	}
	[UIView animateWithDuration:0.2 animations:^()
	 {
		 
		 CGRect mapFrame = _mapView.frame;
		 mapFrame.size.height += verticalShift;
		 _mapView.frame = mapFrame;
		 
		 CGRect searchViewFrame = _searchView.frame;
		 searchViewFrame.origin.y += verticalShift;
		 _searchView.frame = searchViewFrame;
		 
		 CGRect resizeButtonFrame = _resizeButton.frame;
		 resizeButtonFrame.origin.y += verticalShift;
		 _resizeButton.frame = resizeButtonFrame;	 
		 
		 [_resizeButton setImage:[UIImage imageNamed:resizeButtonImageName] forState:UIControlStateNormal];
		 [_resizeButton setImage:[UIImage imageNamed:resizeGlowButtonImageName] forState:UIControlStateHighlighted];
		 
		 CGAffineTransform rotation = CGAffineTransformMakeRotation(backButtonRotation);
		 [_searchView.detailView.backButton setTransform:rotation];
	 }  completion:^(BOOL finished)
	 {
		 if (_transitioningToFullScreen)
		 {
			 dispatch_async(dispatch_get_main_queue(), ^()
							{
								NSArray *annotations = [_mapView annotations];
								[_mapView removeAnnotations:annotations];
								[_mapView addAnnotations:annotations];		
							});
		 _mapView.showsUserLocation = NO;
		 _mapView.showsUserLocation = YES;
		 }
	 }];
}

- (void)_refreshAnnotations
{
	[_mapView removeAnnotation:_mapView.userLocation];
	[_mapView addAnnotation:_mapView.userLocation];
}

- (void)_hideKeyboard
{
	[_searchView.searchBar resignFirstResponder];
	[_searchView selectButton:-1];
}

- (void)_setMapVisible:(BOOL)visible
{
	_locationDisabledView.hidden = visible;
	_resizeButton.enabled = visible;	

	if (visible)
		[_mapView setCenterCoordinate:[[[[DataModel sharedInstance] locationManager] location] coordinate] animated:YES];
}

#pragma mark -
#pragma mark Test methods

- (IBAction)debug:(id)sender
{
	[[[DataModel sharedInstance] coreConnector] showPermissionsFromViewController:self];
}

- (IBAction)printCurrentCenter
{
	CLLocationCoordinate2D position = _mapView.centerCoordinate;
	NSLog(@"%f %f", position.latitude, position.longitude);
}

- (IBAction)currentLocation
{
	NSLog(@"Current location: %@", [[DataModel sharedInstance] currentLocation]);
}

- (IBAction)displayGeofences
{
	[_mapView removeOverlays:[_mapView overlays]];
	if (!_showingGeofences)
	{	
		NSArray *allGeofenceRegions = [[DataModel sharedInstance] getAllGeofenceRegions];
		[_mapView addOverlays:allGeofenceRegions];
		
		_refreshLocation = [[DataModel sharedInstance] geofenceRefreshLocation];
		[_mapView addOverlay:_refreshLocation];
	}
	
	_showingGeofences = !_showingGeofences;
}

- (void)dealloc
{
	_mapView = nil;
	_searchView = nil;
	
	_searchingView = nil;
	_indicatorView = nil;
	
	_resizeButton = nil;
	_keyboardCancelButton = nil;
	
	_slideInLeft = nil;
	_slideInRight = nil;
}

@end
