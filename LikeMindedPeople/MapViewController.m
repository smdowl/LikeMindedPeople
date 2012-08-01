//
//  MapViewController.m
//  LikeMindedPeople
//
//  Created by Shaun Dowling on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import "DataModel.h"
#import "SearchView.h"
#import "SearchBarPanel.h"
#import "TDBadgedCell.h"
#import "GeofenceLocation.h"
#import "SearchBar.h"

#define SHOW_GEOFENCE_LOCATIONS NO
#define RESIZE_BUTTTON_PADDING 5

@interface MapViewController ()

- (void)_removeAllNonUserAnnotations;
- (void)_animateMap:(BOOL)fullScreen;
- (void)_hideKeyboard;

@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize searchView = _searchView;

@synthesize resizeButton = _resizeButton;
@synthesize keyboardCancelButton = _keyboardCancelButton;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[_searchView.searchBarPanel setup];
	
	[_resizeButton setImage:[UIImage imageNamed:@"fullscreen.png"] forState:UIControlStateNormal];
	// TODO: Need custom highlighted button
	[_resizeButton setImage:[UIImage imageNamed:@"fullscreen.png"] forState:UIControlStateHighlighted];
	
	UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
	
	// Need to set us as the delgate because of the map views own gesture reconizers
	pinchRecognizer.delegate = self;  
    [_mapView addGestureRecognizer:pinchRecognizer];
	_mapView.delegate = self;
	
	[_keyboardCancelButton addTarget:self action:@selector(_hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
	[_keyboardCancelButton removeFromSuperview];
	
	_searchConnection = [[GoogleLocalConnection alloc] initWithDelegate:self];
	
	_searchView.searchResultsView.delegate = self;
	_searchView.searchResultsView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// When the view appears, home in on our location
	CLLocation *newLocation = _mapView.userLocation.location;
    
    double scalingFactor = ABS( (cos(2 * M_PI * newLocation.coordinate.latitude / 360.0) ));
    
	// Specify the amound of miles we want to see around our location
	double miles = 2.0;

	MKCoordinateRegion region;
    region.span.latitudeDelta = miles/69.0;
	region.span.longitudeDelta = miles/(scalingFactor * 69.0); 
    region.center = newLocation.coordinate;
    
    [_mapView setRegion:region animated:YES];
	
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
	[dataModel.contextCoreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *connectorPermissions) {
        
    } disabled:^(NSError *err) {
		[dataModel.contextCoreConnector enableFromViewController:self success:nil failure:nil];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// Stop the SearchBarPanel recieving notifications
	
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

- (IBAction)debug:(id)sender
{
	[[[DataModel sharedInstance] contextCoreConnector] showPermissionsFromViewController:self];
}

#pragma mark -
#pragma mark SearchBarPanelDelegate

- (void)beginSearchForPlaces:(NSString *)searchText
{
	if (searchText.length)
	{
		[_searchConnection getGoogleObjectsWithQuery:searchText andMapRegion:[_mapView region] andNumberOfResults:20 addressesOnly:YES andReferer:@"http://WWW.radii.com"];    
	}
	else 
	{
		[self _removeAllNonUserAnnotations];
	}
}

- (void)cancelSearch
{
	[self _removeAllNonUserAnnotations];
	[_searchView.searchBarPanel selectButton:-1];
}

#pragma mark -
#pragma mark GoogleConnectionDelegate


- (void) googleLocalConnection:(GoogleLocalConnection *)conn didFinishLoadingWithGoogleLocalObjects:(NSMutableArray *)objects andViewPort:(MKCoordinateRegion)region
{
	if ([objects count] == 0)
	{
		// No results found
	}
	else 
	{				
		// Replace all the annotations with new ones
		[self _removeAllNonUserAnnotations];
		[_mapView addAnnotations:objects];
		
		// Store a ref to the results
		_searchResults = objects;
		
		if (_userLocation)
		{
			[_mapView addAnnotation:_userLocation];
		}
		
		[_searchView setData:_searchResults];
	}
	
	if (SHOW_GEOFENCE_LOCATIONS)
	{
		NSArray *allGeofenceRegions = [[DataModel sharedInstance] getAllGeofenceRegions];
		[_mapView addAnnotations:allGeofenceRegions];
	}
}

- (void) googleLocalConnection:(GoogleLocalConnection *)conn didFailWithError:(NSError *)error
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error finding place - Try again" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	_userLocation = userLocation;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	if (_userLocation)
	{
//		[_mapView addAnnotation:_userLocation];
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
	
	GoogleLocalObject *searchObject = [_searchResults objectAtIndex:indexPath.row];
	cell.textLabel.text = searchObject.title;
	cell.detailTextLabel.text = searchObject.subtitle;
	
	GeofenceLocation *containingGeofence = [[DataModel sharedInstance] getInfoForPin:[searchObject coordinate]];
			
	double rating = containingGeofence ? [containingGeofence rating] : 0.0;
    
	NSString *badge = [NSString stringWithFormat:@"%.0f%@",rating*100,@"%"];    
	
    cell.badgeString = badge;
    cell.badgeColor = [UIColor colorWithRed:rating green:0 blue:0 alpha:1.0];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
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
	if (pinchGestureRecognizer.state != UIGestureRecognizerStateChanged) 
	{
        return;
    }
	
    if([pinchGestureRecognizer scale] > 1 && !_isFullScreen) 
	{
		_isFullScreen = YES;
		[self _animateMap:YES];
	}
	
//	[_mapView addAnnotation:_userLocation];
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
	resizeButtonFrame.origin.y = searchViewFrame.origin.y - _resizeButton.frame.size.height - RESIZE_BUTTTON_PADDING;
	_resizeButton.frame = resizeButtonFrame;
	[UIView commitAnimations];
	
	[self.view insertSubview:_keyboardCancelButton belowSubview:_searchView];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	CGSize viewSize = self.view.frame.size;
	
	[UIView beginAnimations:nil context:nil];
	CGRect searchViewFrame = _searchView.frame;	
	searchViewFrame.origin.y = _isFullScreen ? viewSize.height - _searchView.searchBarPanel.frame.size.height : viewSize.height - _searchView.frame.size.height;
	_searchView.frame = searchViewFrame;
	
	CGRect resizeButtonFrame = _resizeButton.frame;
	resizeButtonFrame.origin.y = searchViewFrame.origin.y - _resizeButton.frame.size.height - RESIZE_BUTTTON_PADDING;
	_resizeButton.frame = resizeButtonFrame;
	[UIView commitAnimations];
	
	[_keyboardCancelButton removeFromSuperview];
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
		
	[UIView beginAnimations:nil context:nil];
		
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
	
	[UIView commitAnimations];
	
	// Also move the map to be centered on the same point
	[_mapView setCenterCoordinate:_mapView.centerCoordinate];
}

- (void)_hideKeyboard
{
	[_searchView.searchBarPanel.searchBar resignFirstResponder];
}

@end
