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
#import "TDBadgedCell.h"
#import "RadiiTableViewCell.h"
#import "SearchBar.h"
#import "RadiiResultDTO.h"
#import "SettingsViewController.h"
#import "DetailViewController.h"
#import "SideBar.h"
#import "MenuViewController.h"
#import "LocationDetailsDTO.h"

#define RESIZE_BUTTTON_PADDING 5
#define MAX_BUTTON_ALPHA 0.4

#define SIDE_BAR_WIDTH 180

#define DEBUG_BUTTONS 1

#define ROUTE_BOUNDING_MULTIPLIER 1.5

#define LOW_CORRELATION_RED 0.0
#define LOW_CORRELATION_GREEN 0.6796875
#define LOW_CORRELATION_BLUE 0.93359375

#define HIGH_CORRELATION_RED 0.433
#define HIGH_CORRELATION_GREEN 0.875
#define HIGH_CORRELATION_BLUE 0.433

#define MAP_HIDDEN_RATIO ((float)3/5)

@interface MapViewController (PrivateUtilities)

- (void)_removeAllNonUserAnnotations;
- (void)_hideKeyboard;
//- (void)_inFromLeft:(UIPanGestureRecognizer *)recognizer;
//- (void)_inFromRight:(UIPanGestureRecognizer *)recognizer;
- (void)_setMapVisible:(BOOL)visible;
- (void)_removeAndStoreAllOtherResults:(RadiiResultDTO *)resultToKeep;
- (void)_restoreResults;
//- (void)_startDownloadingDetailsForView:(DetailViewController *)detailView;
- (void)_animateToMapVisibility:(MapVisible)visibility;
- (void)_showSettingsPage:(id)sender;
- (void)_centerMap;
- (UIImage *)_getImageStringForAnnotationWithType:(NSInteger)type;

@end

@implementation MapViewController


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[[NSBundle mainBundle] loadNibNamed:@"SearchView" owner:self options:nil];
	
	CGRect searchViewFrame = _searchView.frame;
	searchViewFrame.origin.y = CGRectGetMaxY(_mapView.frame) - _searchView.searchBarPanel.frame.size.height;
	searchViewFrame.size.height = self.view.frame.size.height - searchViewFrame.origin.y;
	_searchView.frame = searchViewFrame;
    
	[self.view insertSubview:_searchView belowSubview:_searchingView];
	_searchView.delegate = self;
    
    // Add the pinch gesture to the map so that when the user zooms in and the map is only half visible it goes full screen
	UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
	
	pinchRecognizer.delegate = self;
    #warning TODO
    // TODO: re-enabled the pinch gesure recognizer. at the moment it is making the user disappear
//    [_mapView addGestureRecognizer:pinchRecognizer];
    
//    _mapView.userTrackingMode = MKUserTrackingModeNone;
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
	_mapView.delegate = self;
	_mapView.showsUserLocation = YES;
    
	_searchView.searchResultsView.delegate = self;
	_searchView.searchResultsView.dataSource = self;
	#warning TODO
	// TODO: Maybe take this out
	[[DataModel sharedInstance] addLocationListener:self];
	
#if DEBUG_BUTTONS
	_debugPanel.hidden = NO;
#endif
	
	_storedResults = [NSMutableArray array];
    
    _mapVisible = fullScreen;
    
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setImage:[UIImage imageNamed:@"settingsButton.png"] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(_showSettingsPage:) forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setFrame:CGRectMake(20, 0, 29, 29)];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:settingsButton];
    
    UIButton * centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [centerButton setImage:[UIImage imageNamed:@"centerButton.png"] forState:UIControlStateNormal];
    [centerButton addTarget:self action:@selector(_centerMap) forControlEvents:UIControlEventTouchUpInside];
    [centerButton setFrame:CGRectMake(0, 0, 29, 29)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:centerButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Sometimes a pin is left selected so deselect it
    [self deselectPin];
    
    // Adjust the position of the map view to ensure that it is at the origin of the view. Not really sure why it isn't if you don't do this
    CGRect mapFrame = _mapView.frame;
    mapFrame.origin.y = 0;
    _mapView.frame = mapFrame;
    
    [self _animateToMapVisibility:_mapVisible];
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor clearColor], UITextAttributeTextColor,
                                               [UIColor clearColor], UITextAttributeTextShadowColor,
                                               nil];
    
    self.navigationController.navigationBar.titleTextAttributes = navbarTitleTextAttributes;

}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
	DataModel *dataModel = [DataModel sharedInstance];
    
    // Check whether the gimbal SDK has been enabled
	[dataModel.coreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *connectorPermissions) {
        // If so, just continue as usual
    } disabled:^(NSError *err) {
        // If we haven't already asked for permission once then present the permissions view controller
		if (!_askedForPermission)
		{
			[dataModel.coreConnector enableFromViewController:self success:nil failure:nil];
            _askedForPermission = YES;
		}
		else
		{
			[[[UIAlertView alloc] initWithTitle:@"Permissions" message:@"Without enabling the Gimbal SDK we can't recommend places that match your personality" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			[dataModel.coreConnector enableFromViewController:self success:nil failure:nil];
		}
    }];
    
	if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized)
		[self _setMapVisible:NO];
	else
		[self _setMapVisible:YES];
	
	[[DataModel sharedInstance] updateGeofenceRefreshLocation];
	
    if (!_mapView.showsUserLocation)
    {
        _mapView.showsUserLocation = YES;
//        [self refreshLocation];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	    
    _mapView = nil;
	_searchView = nil;
}

#pragma mark -
#pragma mark SearchViewDelegate

- (void)beginSearchForPlacesWithName:(NSString *)name type:(NSString *)type
{
    
	if (name.length || type.length)
	{
		[_storedResults removeAllObjects];
		
        _searchingView.hidden = NO;
		[_indicatorView startAnimating];
		
//		if (_mapVisible == fullScreen)
//			[self _animateToMapVisibility:halfScreen];
        
        CLLocationCoordinate2D coord = _userLocation.coordinate;
//        _mapView.centerCoordinate
        
        [_mapView setCenterCoordinate:_userLocation.coordinate];
        
		[ServiceAdapter getFourSquareSearchResultsForUser:[[DataModel sharedInstance] apiId] atLocation:coord withQuery:name ? name : type success:^(NSArray *results)
		 {
			 ResultType resultType;
			 if (!type)
				 resultType = other;
			 else if ([type isEqualToString:@"bar"])
				 resultType = bar;
			 else if ([type isEqualToString:@"cafe"])
				 resultType = cafe;
			 else if ([type isEqualToString:@"nightclub"])
				 resultType = club;
             
			 _searchingView.hidden = YES;
			 [_indicatorView stopAnimating];
			 
			 if ([results count] == 0) {
				 [self _removeAllNonUserAnnotations];
			 }
			 else
			 {
				 [self _removeAllNonUserAnnotations];
				 
				 NSMutableArray *newResults = [NSMutableArray arrayWithArray:results];
				 
                 // If the user hasn't done a specific search only include the relevant places
                 #warning TODO
                 // TODO: I have disabled this for now but we will probably want to come up with a way to include some functionality like this
				 if (resultType != other)
				 {
					 NSMutableArray *resultsToRemove = [NSMutableArray array];
					 for (RadiiResultDTO *result in results)
					 {
                         //						 if (result.type != resultType)
                         //							 [resultsToRemove addObject:result];
					 }
					 
					 [newResults removeObjectsInArray:resultsToRemove];
				 }
				 
				 _searchResults = newResults;
				 
				 [_mapView addAnnotations:_searchResults];
				 
                 // This is done to try and ensure the users location doesn't disappear
				 if (_userLocation)
					 [_mapView addAnnotation:_userLocation];
				 
				 [_searchView setData:_searchResults];
			 }
		 }
                                                  failure:^(NSError *error)
		 {
			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem connecting to server" message:@"Please check internet connection and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			 [alert show];
			 
			 _searchingView.hidden = YES;
			 [_indicatorView stopAnimating];
			 
			 // Deselect whatever row was selected when the error occured
//			 [_searchView selectButton:-1];
		 }];
	}
	else
	{
		[self _removeAllNonUserAnnotations];
	}
}

- (void)clearResults
{
	_searchResults = nil;
	[self _removeAllNonUserAnnotations];
	[_searchView setData:nil];
}

- (void)cancelSearch
{
	[_searchView selectButton:-1];
}

- (void)deselectPin
{
	for (id<MKAnnotation> annotation in _mapView.selectedAnnotations)
		[_mapView deselectAnnotation:annotation animated:YES];
}

- (void)slideView:(BOOL)upwards
{
    // In the case where the view is already at an extreme and can't go any further then there is nothing to do
	if (upwards && _mapVisible == mapHidden) return;
    if (!upwards && _mapVisible == fullScreen) return;
    
    // Otherwise increment the view in the desired direction
    NSInteger change = upwards ? 1 : -1;
    MapVisible newMapVisible = _mapVisible + change;
    
    [self _animateToMapVisibility:newMapVisible];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    
	if (!_locationSet)
	{
		_userLocation = userLocation;
		
		// When the view appears, home in on our location
		CLLocation *newLocation = userLocation.location;
		
        NSInteger mileRadius = 5;
        CGFloat distance = 1609.344f * mileRadius;
        
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(
                                                                       newLocation.coordinate,
                                                                       distance,
                                                                       distance
                                                                       );
        
		[_mapView setRegion:region animated:YES];
        
		_locationSet = YES;
	}
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    #warning TODO
	// TODO: trying to stop the user from disappearing. Not 100% sure if this helps
	if (_userLocation)
		[_mapView addAnnotation:_userLocation];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)annotationView
{
	if (annotationView.annotation == _userLocation)
		return;
    
	MKCoordinateRegion region = _mapView.region;
	
	CLLocationCoordinate2D center   = region.center;
	CLLocationCoordinate2D northWestCorner, southEastCorner;
	
	northWestCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0);
	northWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0);
	southEastCorner.latitude  = center.latitude  + (region.span.latitudeDelta  / 2.0);
	southEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0);
	
	CLLocationCoordinate2D annotationCoordinate = annotationView.annotation.coordinate;
	
	// Check to see if that map contains the annotation
	if (annotationCoordinate.latitude > northWestCorner.latitude &&
         annotationCoordinate.longitude < northWestCorner.longitude &&
         annotationCoordinate.latitude > southEastCorner.latitude &&
         annotationCoordinate.longitude > southEastCorner.longitude)
	{
		region.center = CLLocationCoordinate2DMake((center.latitude + annotationCoordinate.latitude)/2, (center.longitude + annotationCoordinate.longitude)/2);
		region.span = MKCoordinateSpanMake(fabsf(annotationCoordinate.latitude - _userLocation.coordinate.latitude), fabsf(annotationCoordinate.longitude - _userLocation.coordinate.longitude));
		
        //		_mapView.region = region;
		[_mapView setRegion:region animated:YES];
	}
    
	
	id<MKAnnotation> annotation = annotationView.annotation;
	if ([annotation isKindOfClass:[RadiiResultDTO class]])
	{		
		RadiiResultDTO *radiiResult = (RadiiResultDTO *)annotation;
        
        NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:[_searchResults indexOfObject:radiiResult] inSection:0];
        
        // Move the table view if it is on screen
        [_searchView.searchResultsView selectRowAtIndexPath:selectedIndex
                                                   animated:YES
                                             scrollPosition:UITableViewScrollPositionMiddle];
    		
		id<MKAnnotation> annotation = annotationView.annotation;
		if ([annotation isKindOfClass:[RadiiResultDTO class]])
		{
			switch (radiiResult.type)
			{
				case food:
					annotationView.image = [UIImage imageNamed:@"food2.png"];
					break;
				case cafe:
					annotationView.image = [UIImage imageNamed:@"cafe2.png"];
					break;
				case bar:
					annotationView.image = [UIImage imageNamed:@"bars2.png"];
					break;
				case club:
					annotationView.image = [UIImage imageNamed:@"club2.png"];
					break;
				default:
					annotationView.image = [UIImage imageNamed:@"shop2.png"];
                break;
            }
		}
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)annotationView
{	
	[self _restoreResults];
	
	id<MKAnnotation> annotation = annotationView.annotation;
	if ([annotation isKindOfClass:[RadiiResultDTO class]])
	{
		RadiiResultDTO *radiiResult = (RadiiResultDTO *)annotation;
        annotationView.image = [self _getImageStringForAnnotationWithType:radiiResult.type];
	}
	
	[_searchView.searchResultsView deselectRowAtIndexPath:[_searchView.searchResultsView indexPathForSelectedRow] animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	MKAnnotationView *annotationView;
	if ([annotation isKindOfClass:[RadiiResultDTO class]])
	{
		RadiiResultDTO *radiiResult = (RadiiResultDTO *)annotation;
		annotationView = [_mapView dequeueReusableAnnotationViewWithIdentifier:@"radiiPin"];
		
		if (!annotationView) {
			annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"radiiPin"];
		}
		else {
			annotationView.annotation = annotation;
		}
		
        annotationView.image = [self _getImageStringForAnnotationWithType:radiiResult.type];
		
		annotationView.centerOffset = CGPointMake(0,-[annotationView.image size].height / 2);
        
        //		annotationView.centerOffset = CGPointMake(0,-annotationView.image.size.height);
	}
    //	else if ([annotation isKindOfClass:[MKUserLocation class]])
//	else if (annotation == _mapView.userLocation)
    else
	{
//		MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:@"mePin"];
//        
//		if (!annotationView)
//		{
//			annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"mePin"];
//			annotationView.animatesDrop = NO;
//			annotationView.canShowCallout = NO;
//		}
//		else
//		{
//			annotationView.annotation = annotation;
//		}
//
        #warning TODO
//		// TODO: use the type of the result to decide on the image for the annotationView
//		annotationView.image = [UIImage imageNamed:@"me_pin.png"];
        
        annotationView = nil;
	}
    
    return annotationView;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
	if ([overlay isKindOfClass:[GeofenceLocation class]])
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
    
    MKPolylineView *polylineView = nil;
	if ([overlay isKindOfClass:[MKPolyline class]])
	{
		MKPolyline *polyline = (MKPolyline *)overlay;
		polylineView = [[MKPolylineView alloc] initWithPolyline:polyline];
		
        //		UIColor *orangeColor = [UIColor colorWithRed:0.984375 green:0.5625 blue:0.0859375 alpha:0.9];
        //		polylineView.strokeColor = orangeColor;
        //		polylineView.fillColor = orangeColor;
		UIColor *blue = [UIColor colorWithRed:0.27734375 green:0.11328125 blue:1.0 alpha:0.8];
		polylineView.strokeColor = blue;
		polylineView.fillColor = blue;
		polylineView.lineWidth = 4;
	}
    return polylineView;
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //	_userLocation = [[MKAnnotation alloc] init];
	[_mapView setCenterCoordinate:[[manager location] coordinate]];
	[manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if (status == kCLAuthorizationStatusAuthorized)
	{
		[self _setMapVisible:YES];
		
		if ([[manager location] coordinate].longitude != 0 && [[manager location] coordinate].longitude != 0)
			[_mapView setCenterCoordinate:[[manager location] coordinate]];
		else
			[manager startUpdatingLocation];
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
	cell.textLabel.font = [UIFont systemFontOfSize:14];
	cell.detailTextLabel.text = radiiResult.peopleHistoryCount ? [NSString stringWithFormat:@"%i %@", radiiResult.peopleHistoryCount, radiiResult.peopleHistoryCount > 1 ? @"ratings" : @"rating"] : @"Be the first one here";
	
	if (radiiResult.peopleHistoryCount)
	{
		
		NSString *badgeString = [NSString stringWithFormat:@"%.0f%@",radiiResult.rating*100,@"%"];
		
		cell.badgeString = badgeString;
		
		cell.badgeColor = [UIColor colorWithRed:radiiResult.rating * HIGH_CORRELATION_RED + (1 - radiiResult.rating) * LOW_CORRELATION_RED
										  green:radiiResult.rating * HIGH_CORRELATION_GREEN + (1 - radiiResult.rating) * LOW_CORRELATION_GREEN
										   blue:radiiResult.rating * HIGH_CORRELATION_BLUE + (1 - radiiResult.rating) * LOW_CORRELATION_BLUE
										  alpha:1.0];
	}
	else
	{
		cell.badgeColor = [UIColor clearColor];
        //		NSString *badgeString = [NSString stringWithFormat:@"0%%"];
        //
        //		cell.badgeString = badgeString;
        //
        //		cell.badgeColor = [UIColor colorWithRed:LOW_CORRELATION_RED
        //										  green:LOW_CORRELATION_GREEN
        //										   blue:LOW_CORRELATION_BLUE
        //										  alpha:1.0];
	}
	
    return cell;
	
    //	RadiiTableViewCell *cell = (RadiiTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    //	if (!cell)
    //	{
    //		cell = [[RadiiTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    //		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    //		[[NSBundle mainBundle] loadNibNamed:@"RadiiTableViewCell" owner:cell options:nil];
    //	}
    //
    //
    //	RadiiResultDTO *radiiResult = [_searchResults objectAtIndex:indexPath.row];
    //
    //	cell.nameLabel.text = radiiResult.businessTitle;
    //	cell.peopleHistoryCountLabel.text = radiiResult.peopleHistoryCount ? [NSString stringWithFormat:@"%i %@", radiiResult.peopleHistoryCount, radiiResult.peopleHistoryCount > 1 ? @"ratings" : @"rating"] : @"Not yet rated";
    //
    //	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	// To select the pin for the given item. I don't think this makes sense
//	for (id<MKAnnotation> annotation in _mapView.annotations)
//	{
//		if ([annotation isEqual:[_searchResults objectAtIndex:indexPath.row]])
//			[_mapView selectAnnotation:annotation animated:YES];
//	}
    
    DetailViewController *detailController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
	[self.navigationController pushViewController:detailController animated:YES];
	detailController.data = [_searchResults objectAtIndex:indexPath.row];
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
			if([pinchGestureRecognizer scale] > 1 && !_mapVisible == fullScreen)
			{
				_transitioningToFullScreen = YES;
				[self _animateToMapVisibility:fullScreen];
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
	
    CGRect searchViewFrame;
    // Reposition the searchView depending on what mode it is in
    if (_mapVisible != mapHidden)
    {
        searchViewFrame = _searchView.frame;
        searchViewFrame.origin.y = viewSize.height - keyboardSize.height - _searchView.searchBar.frame.size.height;
    }
    else
    {
        searchViewFrame = _searchView.frame;
        searchViewFrame.origin.y = 0;
    }
    
    [UIView beginAnimations:nil context:nil];
    _searchView.frame = searchViewFrame;
    [UIView commitAnimations];
    
    _keyboardCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _keyboardCancelButton.frame = self.view.frame;
    [_keyboardCancelButton addTarget:self action:@selector(_hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:_keyboardCancelButton belowSubview:_searchView];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	CGSize viewSize = self.view.frame.size;
	
	[UIView beginAnimations:nil context:nil];
	CGRect searchViewFrame = _searchView.frame;
	searchViewFrame.origin.y = _mapVisible == fullScreen ? viewSize.height - [_searchView panelHeight] : viewSize.height - _searchView.frame.size.height;
	_searchView.frame = searchViewFrame;
    
    if (_keyboardCancelButton)
    {
        [_keyboardCancelButton removeFromSuperview];
        _keyboardCancelButton = nil;
    }
}

#pragma mark -
#pragma mark IBActions

- (IBAction)printCurrentCenter
{
	CLLocationCoordinate2D position = _mapView.centerCoordinate;
	NSLog(@"%f %f", position.latitude, position.longitude);
}

- (IBAction)currentLocation
{
	NSArray *currentLocations = [[DataModel sharedInstance] currentLocations];
	NSLog(@"Current location: %@", currentLocations);
	
	NSMutableString *alertString = [NSMutableString string];
	for (GeofenceLocation *geofence in currentLocations)
	{
		[alertString appendFormat:@"•%@\n", geofence.geofenceName];
	}
	
	
	UIAlertView *currentLocationsAlert;
	
	if ([currentLocations count])
		currentLocationsAlert = [[UIAlertView alloc] initWithTitle:@"Checked in locations" message:alertString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	else
		currentLocationsAlert = [[UIAlertView alloc] initWithTitle:@"Not checked in" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[currentLocationsAlert show];
}

- (IBAction)displayGeofences
{
	for (id<MKOverlay> overlay in [_mapView overlays])
			[_mapView removeOverlay:overlay];
	
	if (!_showingGeofences)
	{
		NSArray *allGeofenceRegions = [[DataModel sharedInstance] getAllGeofenceRegions];
		[_mapView addOverlays:allGeofenceRegions];
		
		_refreshLocation = [[DataModel sharedInstance] geofenceRefreshLocation];
		[_mapView addOverlay:_refreshLocation];
	}
	
	_showingGeofences = !_showingGeofences;
}

- (IBAction)refreshLocation
{
    CLLocation *newLocation = _userLocation.location;
    
    NSInteger mileRadius = 5;
    CGFloat distance = 1609.344f * mileRadius;
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(
                                                                   newLocation.coordinate,
                                                                   distance,
                                                                   distance
                                                                   );
    
    [_mapView setRegion:region animated:YES];
}

- (IBAction)showDetailView
{
    DetailViewController *detailController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    [self.navigationController pushViewController:detailController animated:YES];
}

- (IBAction)enableLocationServices
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
}

@end

#pragma mark -
#pragma mark Private Methods

@implementation MapViewController (PrivateUtilities)

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
    
	if (visible)
		[_mapView setCenterCoordinate:[[[[DataModel sharedInstance] locationManager] location] coordinate] animated:YES];
}

- (void)_removeAndStoreAllOtherResults:(RadiiResultDTO *)resultToKeep
{
	for (id<MKAnnotation> annotation in _searchResults)
	{
		if (annotation != resultToKeep && annotation != _userLocation)
		{
			[_mapView removeAnnotation:annotation];
			[_storedResults addObject:annotation];
		}
	}
}

- (void)_restoreResults
{
	for (id<MKAnnotation> annotation in _storedResults)
		[_mapView addAnnotation:annotation];
}

- (void)_centerMap
{
    [_mapView setCenterCoordinate:_userLocation.coordinate];
}


- (void)_animateToMapVisibility:(MapVisible)mapVisibility
{
    CGFloat searchViewOrigin;
    
    switch (mapVisibility)
    {
        case fullScreen:
            searchViewOrigin = self.view.frame.size.height - _searchView.searchBarPanel.frame.size.height;
            break;
        case halfScreen:
            searchViewOrigin = floor(MAP_HIDDEN_RATIO * self.view.frame.size.height);
            break;
        case mapHidden:
            searchViewOrigin = 0;
            break;
        default:
            break;
    }
    
    // If going to hidden then deselect the pin if one is selected because it is confusing
    if (mapVisibility == mapHidden)
        [self deselectPin];
        
    [UIView animateWithDuration:0.2 animations:^()
     {
         CGRect mapFrame = _mapView.frame;
         mapFrame.size.height = searchViewOrigin - mapFrame.origin.y;
         _mapView.frame = mapFrame;
         
         CGRect searchViewFrame = _searchView.frame;
         searchViewFrame.origin.y = searchViewOrigin;
         searchViewFrame.size.height = self.view.frame.size.height - searchViewOrigin;
         _searchView.frame = searchViewFrame;
     }
                     completion:^(BOOL finished)
     {
         if (_transitioningToFullScreen)
         {
             dispatch_async(dispatch_get_main_queue(), ^()
                            {
                                NSArray *annotations = [_mapView annotations];
                                [_mapView removeAnnotations:annotations];
                                [_mapView addAnnotations:annotations];
                            });
         }
         
         _mapVisible = mapVisibility;
         
     }];
}

- (void)_showSettingsPage:(id)sender
{    
    SettingsViewController *settingsController = [[SettingsViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    
    navController.navigationBar.tintColor = [UIColor lightGrayColor];
    
    [self.navigationController presentModalViewController:navController animated:YES];
}

- (UIImage *)_getImageStringForAnnotationWithType:(NSInteger)type
{
    switch (type)
    {
        case food:
            return [UIImage imageNamed:@"food_pin.png"];
            break;
        case cafe:
            return [UIImage imageNamed:@"cafe_pin.png"];
            break;
        case bar:
            return [UIImage imageNamed:@"bars_pin.png"];
            break;
        case club:
            return [UIImage imageNamed:@"club_pin.png"];
            break;
        default:
            return [UIImage imageNamed:@"shop_pin.png"];
            break;
    }

}

@end
