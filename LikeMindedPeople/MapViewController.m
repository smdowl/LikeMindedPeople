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
#import "DetailViewController.h"
#import "SideBar.h"
#import "DirectionsPathDTO.h"
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

// What ratio of the map should the results cover
#define MAP_HIDDEN_RATIO ((float)3/5)

@interface MapViewController (PrivateUtilities)

- (void)_removeAllNonUserAnnotations;
- (void)_hideKeyboard;

//- (void)_inFromLeft:(UIPanGestureRecognizer *)recognizer;
//- (void)_inFromRight:(UIPanGestureRecognizer *)recognizer;

- (void)_setMapVisible:(BOOL)visible; // Either show or hide the map (at the moment dependent on whether location services has been enabled)

- (void)_removeAndStoreAllOtherResults:(RadiiResultDTO *)resultToKeep;
- (void)_restoreResults;	// Add the radii results that were removed back to the map

//- (void)_startDownloadingDetailsForView:(DetailViewController *)detailView;

- (void)_animateToMapVisibility:(MapVisible)visibility;

@end

@implementation MapViewController

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
    
	[self.view insertSubview:_searchView belowSubview:_searchingView];
	_searchView.delegate = self;
    
	UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
	
	// Need to set us as the delgate because of the map views own gesture reconizers
	pinchRecognizer.delegate = self;
    [_mapView addGestureRecognizer:pinchRecognizer];
    _mapView.userTrackingMode = MKUserTrackingModeNone;
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
	
	_storedResults = [NSMutableArray array];
    
    _mapVisible = fullScreen;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add the buttons to the navigation bar
    //    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateNormal];
    
    UIImage *settingsImage = [UIImage imageNamed:@"settings.png"];
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStylePlain target:self action:@selector(debug:)];
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    UIBarButtonItem* rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStyleBordered target:self action:@selector(showDetailView)];
    rightButton.tintColor = [UIColor darkGrayColor];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    // Adjust the position of the map view to ensure that it is at the origin of the view
    CGRect mapFrame = _mapView.frame;
    mapFrame.origin.y = 0;
    _mapView.frame = mapFrame;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headerlogoandbg.png"]];
    
    CGRect imageFrame = imageView.frame;
    imageFrame.size = self.navigationController.navigationBar.frame.size;
    imageView.frame = imageFrame;
    
//    self.navigationItem.titleView = imageView;
    
    [self _animateToMapVisibility:_mapVisible];
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
		if (!_askedForPermission)
		{
			[dataModel.coreConnector enableFromViewController:self success:nil failure:nil];
		}
		else
		{
			[[[UIAlertView alloc] initWithTitle:@"Permissions" message:@"Without enabling the Gimbal SDK we can't recommend places that match your personality" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			[dataModel.coreConnector enableFromViewController:self success:nil failure:nil];
		}
		
		_askedForPermission = YES;
    }];
	
	if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized)
	{
		[self _setMapVisible:NO];
		
        //		_locationManager.delegate = self;
	}
	else
	{
		[self _setMapVisible:YES];
	}
	
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
	
    // Stop the SearchBarPanel recieving notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
    _mapView.showsUserLocation = NO;
    
    _mapView = nil;
	_searchView = nil;
}

- (IBAction)enableLocationServices
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
}

#pragma mark -
#pragma mark SearchViewDelegate

- (void)beginSearchForPlacesWithName:(NSString *)name type:(NSString *)type
{
	if (name.length || type.length)
	{
		[_mapView removeOverlay:_directionsLine];
		_directionsLine = nil;
		
		[_storedResults removeAllObjects];
		
        //		[_searchConnection getGoogleObjectsWithQuery:searchText andMapRegion:[_mapView region] andNumberOfResults:20 addressesOnly:YES andReferer:@"http://WWW.radii.com"];
        //		[ServiceAdapter getGoogleSearchResultsForUser:[[DataModel sharedInstance] userId] atLocation:_mapView.centerCoordinate withName:name withType:type success:^(NSArray *results)
		[ServiceAdapter getFourSquareSearchResultsForUser:[[DataModel sharedInstance] apiId] atLocation:_mapView.centerCoordinate withQuery:name ? name : type success:^(NSArray *results)
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
			 
			 if ([results count] == 0)
			 {
				 [self _removeAllNonUserAnnotations];
			 }
			 else
			 {
				 // Replace all the annotations with new ones
				 [self _removeAllNonUserAnnotations];
				 
				 NSMutableArray *newResults = [NSMutableArray arrayWithArray:results];
				 
                 // If the user hasn't done a specific search only include the relavent places
                 // (I have disabled this for now but we will probably want to come up with a way to include some functionality like this)
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
				 
				 // Add the repackaged results as annotations
				 [_mapView addAnnotations:_searchResults];
				 
				 if (_userLocation)
				 {
					 [_mapView addAnnotation:_userLocation];
				 }
				 
				 [_searchView setData:_searchResults];
			 }
		 }
                                                  failure:^(NSError *error)
		 {
             //			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error finding place - Try again" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem connecting to server" message:@"Please check internet connection and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			 [alert show];
			 
			 _searchingView.hidden = YES;
			 [_indicatorView stopAnimating];
			 
			 // Deselect whatever row was selected when the error occured
			 [_searchView selectButton:-1];
		 }
		 ];
		_searchingView.hidden = NO;
		[_indicatorView startAnimating];
		
		if (_mapVisible == fullScreen)
			[self _animateToMapVisibility:halfScreen];
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

- (void)showMenu:(NSString *)urlString
{
	MenuViewController *menuController = [[MenuViewController alloc] initWithNibName:nil bundle:nil];
	menuController.menuURLString = urlString;
	
	[self presentModalViewController:menuController animated:YES];
}

- (void)getDirectionsToLocation:(RadiiResultDTO *)location
{
	[ServiceAdapter getDirectionsFromLocation:_mapView.userLocation.coordinate toLocation:location.coordinate onSuccess:^(NSDictionary *result)
	 {
		 [self _removeAndStoreAllOtherResults:location];
		 
		 NSLog(@"%@", result);
		 NSLog(@"keys: %@", [[result objectForKey:@"routes"] objectAtIndex:0]);
		 NSDictionary *route = [[result objectForKey:@"routes"] objectAtIndex:0];
		 
		 NSDictionary *leg = [[route objectForKey:@"legs"] objectAtIndex:0];
		 NSString *distance = [[leg objectForKey:@"distance"] objectForKey:@"text"];
		 NSString *duration = [[leg objectForKey:@"duration"] objectForKey:@"text"];
         
		 NSDictionary *directionsDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:distance,duration,nil]
																		  forKeys:[NSArray arrayWithObjects:@"distance", @"duration", nil]];
//		 _searchView.detailView.directionsDictionary = directionsDictionary;
		 
		 NSString *polylineString = [[route objectForKey:@"overview_polyline"] objectForKey:@"points"];
		 NSArray *path = [MapViewController decodePolylineOfGoogleMaps:polylineString];
		 NSLog(@"%@", path);
		 
         //		 DirectionsPathDTO *directionPath = [[DirectionsPathDTO alloc] initWithPath:path];
		 CLLocationCoordinate2D locations[path.count];
		 
		 CGPoint minLatLong = CGPointMake(MAXFLOAT,MAXFLOAT);
		 CGPoint maxLatLong = CGPointMake(-MAXFLOAT,-MAXFLOAT);
		 
		 for (int i=0; i<path.count; i++)
         {
             NSValue *pathValue = [path objectAtIndex:i];
             
             CLLocationCoordinate2D location;
             location.latitude = pathValue.CGPointValue.x;
             location.longitude = pathValue.CGPointValue.y;
             
             if (location.latitude < minLatLong.x)
                 minLatLong.x = location.latitude;
             if (location.longitude < minLatLong.y)
                 minLatLong.y = location.longitude;
             
             if (location.latitude > maxLatLong.x)
                 maxLatLong.x = location.latitude;
             if (location.longitude > maxLatLong.y)
                 maxLatLong.y = location.longitude;
             
             locations[i] = location;
         }
		 
		 [_mapView removeOverlay:_directionsLine];
		 _directionsLine = [MKPolyline polylineWithCoordinates:locations count:path.count];
		 [_mapView addOverlay:_directionsLine];
		 
		 MKCoordinateRegion region;
		 region.span.latitudeDelta = ROUTE_BOUNDING_MULTIPLIER * (maxLatLong.x - minLatLong.x);
		 region.span.longitudeDelta = ROUTE_BOUNDING_MULTIPLIER * (maxLatLong.y - minLatLong.y);
		 region.center = CLLocationCoordinate2DMake(minLatLong.x + region.span.latitudeDelta/(2 * ROUTE_BOUNDING_MULTIPLIER), minLatLong.y + region.span.longitudeDelta / (2 * ROUTE_BOUNDING_MULTIPLIER));
		 
		 [_mapView setRegion:region animated:YES];
		 [_mapView setNeedsDisplay];
	 }
									  failure:^(NSError *error)
	 {
		 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bad internet connection" message:NSStringFromSelector(_cmd) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		 [alertView show];
	 }];
}

/**
 * Decode polyline of google maps.
 *
 * @param encodedPolyline: Polyline encoded of google maps.
 * @return An array that contain all coordinates.
 */
+ (NSArray *)decodePolylineOfGoogleMaps:(NSString *)encodedPolyline {
    
    NSUInteger length = [encodedPolyline length];
    NSInteger index = 0;
    NSMutableArray *points = [NSMutableArray array];
    CGFloat lat = 0.0f;
    CGFloat lng = 0.0f;
    
    while (index < length)
	{
        
        // Temorary variable to hold each ASCII byte.
        int b = 0;
        
        // The encoded polyline consists of a latitude value followed by a
        // longitude value. They should always come in pair. Read the
        // latitude value first.
        int shift = 0;
        int result = 0;
        
        do {
            
            // If index exceded lenght of encoding, finish 'chunk'
            if (index >= length) {
                
                b = 0;
                
            } else {
				
                // The '[encodedPolyline characterAtIndex:index++]' statement resturns the ASCII
                // code for the characted at index. Subtract 63 to get the original
                // value. (63 was added to ensure proper ASCII characters are displayed
                // in the encoded plyline string, wich id 'human' readable)
                b = [encodedPolyline characterAtIndex:index++] - 63;
                
            }
            
            // AND the bits of the byte with 0x1f to get the original 5-bit 'chunk'.
            // Then left shift the bits by the required amount, wich increases
            // by 5 bits each time.
            // OR the value into results, wich sums up the individual 5-bit chunks
            // into the original value. Since the 5-bit chunks were reserved in
            // order during encoding, reading them in this way ensures proper
            // summation.
            result |= (b & 0x1f) << shift;
            shift += 5;
            
        } while (b >= 0x20); // Continue while the read byte is >= 0x20 since the last 'chunk'
		// was nor OR'd with 0x20 during the conversion process. (Signals the end).
		
        // check if negative, and convert. (All negative values have the last bit set)
        CGFloat dlat = (result & 1) ? ~(result >> 1) : (result >> 1);
        
        //Compute actual latitude since value is offset from previous value.
        lat += dlat;
        
        // The next value will correspond to the longitude for this point.
        shift = 0;
        result = 0;
        
        do {
            
            // If index exceded lenght of encoding, finish 'chunk'
            if (index >= length) {
                
                b = 0;
                
            } else {
				
                b = [encodedPolyline characterAtIndex:index++] - 63;
                
            }
            result |= (b & 0x1f) << shift;
            shift += 5;
            
        } while (b >= 0x20);
        
        CGFloat dlng = (result & 1) ? ~(result >> 1) : (result >> 1);
        lng += dlng;
        
        // The actual latitude and longitude values were multiplied by
        // 1e5 before encoding so that they could be converted to a 32-bit
        //integer representation. (With a decimal accuracy of 5 places)
        // Convert back to original value.
        //        [points addObject:[NSString stringWithFormat:@"%f", (lat * 1e-5)]];
        //        [points addObject:[NSString stringWithFormat:@"%f", (lng * 1e-5)]];
        [points addObject:[NSValue valueWithCGPoint:CGPointMake((lat * 1e-5),(lng * 1e-5))]];
    }
    
    return points;
    
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
	if ((annotationCoordinate.latitude > northWestCorner.latitude &&
         annotationCoordinate.longitude < northWestCorner.longitude &&
         annotationCoordinate.latitude > southEastCorner.latitude &&
         annotationCoordinate.longitude > southEastCorner.longitude))
	{
		region.center = CLLocationCoordinate2DMake((center.latitude + annotationCoordinate.latitude)/2, (center.longitude + annotationCoordinate.longitude)/2);
		region.span = MKCoordinateSpanMake(fabsf(annotationCoordinate.latitude - _userLocation.coordinate.latitude), fabsf(annotationCoordinate.longitude - _userLocation.coordinate.longitude));
		
        //		_mapView.region = region;
		[_mapView setRegion:region animated:YES];
	}
    
	
	id<MKAnnotation> annotation = annotationView.annotation;
	if ([annotation isKindOfClass:[RadiiResultDTO class]])
	{
		// Stop the timer from hiding the view
		[_detailViewTimer invalidate];
		
		RadiiResultDTO *radiiResult = (RadiiResultDTO *)annotation;
		
//		if (!_searchView.detailView.isShowing)
//		{
//			if (_mapVisible == fullScreen)
//			{
//				if (!_searchView.detailView.isShowing)
//					[_searchView showDetailView];
//				
//				// After adding the detail view, remove the targets and then add self
//				[_searchView.detailView.backButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
//				[_searchView.detailView.backButton addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventTouchUpInside];
//				CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);
//				[_searchView.detailView.backButton setTransform:rotation];
//			}
//			else
//			{
				NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:[_searchResults indexOfObject:radiiResult] inSection:0];
				
				// Move the table view if it is on screen
				[_searchView.searchResultsView selectRowAtIndexPath:selectedIndex
														   animated:YES
													 scrollPosition:UITableViewScrollPositionMiddle];
//			}
//		}
    		
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
	[_mapView removeOverlay:_directionsLine];
	_directionsLine = nil;
	
	[self _restoreResults];
	
	id<MKAnnotation> annotation = annotationView.annotation;
	if ([annotation isKindOfClass:[RadiiResultDTO class]])
	{
		RadiiResultDTO *radiiResult = (RadiiResultDTO *)annotation;
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
				annotationView.image = [UIImage imageNamed:@"shop_pin.png"];
				break;
		}
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
				annotationView.image = [UIImage imageNamed:@"shop_pin.png"];
				break;
		}
		
		annotationView.centerOffset = CGPointMake(0,-[annotationView.image size].height / 2);
        
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
    //	else if ([overlay isKindOfClass:[DirectionsPathDTO class]])
    //	{
    //		DirectionsPathDTO *directionsPath = (DirectionsPathDTO *)overlay;
    //		MKOverlayPathView *pathView = [[MKOverlayPathView alloc] initWithOverlay:overlay];
    //		pathView.path = directionsPath.mapKitPath;
    //		pathView.strokeColor = [UIColor blackColor];
    //		return pathView;
    //	}
	else if ([overlay isKindOfClass:[MKPolyline class]])
	{
		MKPolyline *polyline = (MKPolyline *)overlay;
		MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:polyline];
		
		UIColor *orangeColor = [UIColor colorWithRed:0.984375 green:0.5625 blue:0.0859375 alpha:0.9];
        //		polylineView.strokeColor = orangeColor;
        //		polylineView.fillColor = orangeColor;
		UIColor *blue = [UIColor colorWithRed:0.27734375 green:0.11328125 blue:1.0 alpha:0.8];
		polylineView.strokeColor = blue;
		polylineView.fillColor = blue;
		polylineView.lineWidth = 4;
		return polylineView;
	}
	else
	{
		return nil;
	}
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
	
	for (id<MKAnnotation> annotation in _mapView.annotations)
	{
		if ([annotation isEqual:[_searchResults objectAtIndex:indexPath.row]])
			[_mapView selectAnnotation:annotation animated:YES];
	}
       
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
								   
								   if (_directionsLine)
									   [_mapView addOverlay:_directionsLine];
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
	searchViewFrame.origin.y = viewSize.height - keyboardSize.height - _searchView.searchBar.frame.size.height;
	_searchView.frame = searchViewFrame;
    
	[self.view insertSubview:_keyboardCancelButton belowSubview:_searchView];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	CGSize viewSize = self.view.frame.size;
	
	[UIView beginAnimations:nil context:nil];
	CGRect searchViewFrame = _searchView.frame;
	searchViewFrame.origin.y = _mapVisible == fullScreen ? viewSize.height - [_searchView panelHeight] : viewSize.height - _searchView.frame.size.height;
	_searchView.frame = searchViewFrame;
    
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
	{
		if (overlay != _directionsLine)
			[_mapView removeOverlay:overlay];
	}
	
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

- (void)dealloc
{
	_mapView = nil;
	_searchView = nil;
	
	_searchingView = nil;
	_indicatorView = nil;
	
	_keyboardCancelButton = nil;
	
	_slideInLeft = nil;
	_slideInRight = nil;
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
    
    CGFloat backButtonRotation = mapVisibility == fullScreen ? M_PI_2 : 0;
    
    // Remove all targets from the back button
//    [_searchView.detailView.backButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    // Either set it to remove from screen on return to normal view
    
    // TODO: At the moment this is no use, need to work out how to implement better
//    if (mapVisibility == fullScreen)
//    {
//        [_searchView.detailView.backButton addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    else
//    {
//        [_searchView.detailView.backButton addTarget:_searchView action:@selector(hideDetailView) forControlEvents:UIControlEventTouchUpInside];
//    }
    
    [UIView animateWithDuration:0.2 animations:^()
     {
         CGRect mapFrame = _mapView.frame;
         mapFrame.size.height = searchViewOrigin - mapFrame.origin.y;
         _mapView.frame = mapFrame;
         
         CGRect searchViewFrame = _searchView.frame;
         searchViewFrame.origin.y = searchViewOrigin;
         searchViewFrame.size.height = self.view.frame.size.height - searchViewOrigin;
         _searchView.frame = searchViewFrame;
                           
         CGAffineTransform rotation = CGAffineTransformMakeRotation(backButtonRotation);
//         [_searchView.detailView.backButton setTransform:rotation];
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
         
         // Had this in because the users locations seemed to disappear sometimes
         //		 if (![[_mapView annotations] containsObject:_userLocation])
         //		 {
         //			 _mapView.showsUserLocation = NO;
         //			 _mapView.showsUserLocation = YES;
         //		 }
         
     }];
}

@end
