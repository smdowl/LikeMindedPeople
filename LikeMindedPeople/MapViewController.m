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
#import "RAdiiResultDTO.h"
#import "DetailView.h"
#import "SideBar.h"

#define SHOW_GEOFENCE_LOCATIONS NO
#define RESIZE_BUTTTON_PADDING 5
#define MAX_BUTTON_ALPHA 0.4

#define SIDE_BAR_WIDTH 180

@interface MapViewController ()

- (void)_removeAllNonUserAnnotations;
- (void)_animateMap:(BOOL)fullScreen;
- (void)_hideKeyboard;

- (void)_inFromLeft:(UIPanGestureRecognizer *)recognizer;
- (void)_inFromRight:(UIPanGestureRecognizer *)recognizer;

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
	_mapView.showsUserLocation = YES;
	
	[_keyboardCancelButton addTarget:self action:@selector(_hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
	[_keyboardCancelButton removeFromSuperview];
	
	_searchConnection = [[GoogleLocalConnection alloc] initWithDelegate:self];
	
	_searchView.searchResultsView.delegate = self;
	_searchView.searchResultsView.dataSource = self;
	
	// Recognizing gestures on the left side of the screen
	UIPanGestureRecognizer *leftSwipeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_inFromLeft:)];
	[_slideInLeft addGestureRecognizer:leftSwipeGestureRecognizer];
	
	// Recognizing gestures on the right side of the screen
	UIPanGestureRecognizer *rightSwipeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_inFromRight:)];
	[_slideInRight addGestureRecognizer:rightSwipeGestureRecognizer];
	
	[_searchView.detailView.backButton addTarget:_searchView action:@selector(hideDetailView) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
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
	[[[DataModel sharedInstance] coreConnector] showPermissionsFromViewController:self];
}

#pragma mark -
#pragma mark SearchBarPanelDelegate

- (void)beginSearchForPlaces:(NSString *)searchText
{
	if (searchText.length)
	{
		[_searchConnection getGoogleObjectsWithQuery:searchText andMapRegion:[_mapView region] andNumberOfResults:20 addressesOnly:YES andReferer:@"http://WWW.radii.com"];    
		_searchingView.hidden = NO;
		[_indicatorView startAnimating];
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
	_searchingView.hidden = YES;
	[_indicatorView stopAnimating];
	
	if ([objects count] == 0)
	{
		// No results found
	}
	else 
	{				
		// Replace all the annotations with new ones
		[self _removeAllNonUserAnnotations];
		
		NSMutableArray *resultsArray = [NSMutableArray array];
		
		// Store the results as RadiiResultsDTOs
		for (GoogleLocalObject *googleObject in objects)
		{
			RadiiResultDTO *result = [[RadiiResultDTO alloc] init];
			result.businessTitle = googleObject.title;
			result.description = googleObject.subtitle;
			
			GeofenceLocation *containingGeofence = [[DataModel sharedInstance] getInfoForPin:[googleObject coordinate]];
			double rating = containingGeofence ? [containingGeofence rating] : 0.0;
			
			// TODO: cut out these iVars
			result.rating = rating;
			
			result.peopleCount = 0;
			result.relatedInterests = nil;
			result.searchLocation = googleObject.coordinate;
			
			[resultsArray addObject:result];
		}
		
		_searchResults = [NSArray arrayWithArray:resultsArray];
		
		// Add the repackaged results as annotations
		[_mapView addAnnotations:_searchResults];
		
		
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
	
	_searchingView.hidden = YES;
	[_indicatorView stopAnimating];
	
	// Deselect whatever row was selected when the error occured
	[_searchView.searchBarPanel selectButton:-1];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	_userLocation = userLocation;
	
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
	
	// Update the detail view
	[_searchView.detailView setData:result];
	
	if (_isFullScreen)
	{
		[_searchView showDetailView];
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	[_searchView.searchResultsView deselectRowAtIndexPath:[_searchView.searchResultsView indexPathForSelectedRow] animated:YES];
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
	cell.detailTextLabel.text = radiiResult.description;
	
	NSString *badgeString = [NSString stringWithFormat:@"%.0f%@",radiiResult.rating*100,@"%"];    
	
    cell.badgeString = badgeString;
    cell.badgeColor = [UIColor colorWithRed:radiiResult.rating green:0 blue:0 alpha:1.0];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// Set the detail view's data. This fill in the UI
	_searchView.detailView.data = [_searchResults objectAtIndex:indexPath.row];
	[_searchView showDetailView];
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
	
	CGAffineTransform rotation = CGAffineTransformMakeRotation(backButtonRotation);
	[_searchView.detailView.backButton setTransform:rotation];
	[UIView commitAnimations];
	
	// Also move the map to be centered on the same point
//	[_mapView setCenterCoordinate:_mapView.centerCoordinate];
}

- (void)_hideKeyboard
{
	[_searchView.searchBarPanel.searchBar resignFirstResponder];
	[_searchView.searchBarPanel selectButton:-1];
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
