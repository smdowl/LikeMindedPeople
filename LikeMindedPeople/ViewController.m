//
//  ViewController.m
//  test
//
//  Created by Tyler Weitzman on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "GoogleLocalObject.h" 
#import "GTMNSString+URLArguments.h"
@implementation ViewController
@synthesize fbLogin, fbButton;
- (void)viewDidLoad
{
    [super viewDidLoad];
    full=false;
	// Do any additional setup after loading the view, typically from a nib.
    dm = [DataModel sharedInstance];
    locationManager = [[CLLocationManager alloc] init];    
    googleLocalConnection = [[GoogleLocalConnection alloc] initWithDelegate:self];
    UIButton *all = (UIButton*)[self.view viewWithTag:1];
    all.enabled = FALSE;
    selectedCategory=1;
    mapView.delegate = self;
    circleView.hidden = YES;
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinchRecognizer.delegate = self;
    [mapView addGestureRecognizer:pinchRecognizer];    
}
-(IBAction)category:(id)sender {
    UIButton *btn = (UIButton*)sender;
    UIButton *oldBtn = (UIButton*)[self.view viewWithTag:selectedCategory];
    oldBtn.enabled = TRUE;
    btn.enabled = FALSE;
    selectedCategory = btn.tag;
}
-(IBAction)fullScreen:(id)sender {
//    UIView *whiteScreen = [[UIView alloc] initWithFrame:self.view.frame];
//    [whiteScreen setBackgroundColor:[UIColor whiteColor]];
//     [whiteScreen setTag:999];
//    [self.view bringSubviewToFront:circleView];
    full = true;
    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:1.5];
//    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.5];
//    [UIView setAnimationCurve:UIView];    
//    CGRect rect = CGRectMake(-50, -50, 400, 550);
//    [circleView setFrame:CGRectMake(-100,-100,520,650)];
    mapView.frame = CGRectMake(0,-200,320,708);
    btnFull.alpha = 0;
    btnMin.alpha = 1;
    [UIView commitAnimations];
//    btnFull.hidden = YES;
     
}
#pragma mark -
#pragma mark UIPinchGestureRecognizer

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchRecognizer {
    if (pinchRecognizer.state != UIGestureRecognizerStateChanged) {
        return;
    }
    if([pinchRecognizer scale]>1) {
        [self fullScreen:nil];
    } else {
//        [self minimize:nil];
    }
    /*
    if(!full)
    [self fullScreen:nil];
    else {
        [self minimize:nil];
    }*/
    /*
    
    MKMapView *aMapView = (MKMapView *)pinchRecognizer.view;
    
    for (id <MKAnnotation>annotation in aMapView.annotations) {
        // if it's the user location, just return nil.
        if ([annotation isKindOfClass:[MKUserLocation class]])
            return;
        
        // handle our custom annotations
        //
        if ([annotation isKindOfClass:[MKPointAnnotation class]])
        {
            // try to retrieve an existing pin view first
            MKAnnotationView *pinView = [aMapView viewForAnnotation:annotation];
            //Format the pin view
            [self formatAnnotationView:pinView forMapView:aMapView];
        }
    }    
     */
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
-(IBAction)minimize:(id)sender {
    //    UIView *whiteScreen = [[UIView alloc] initWithFrame:self.view.frame];
    //    [whiteScreen setBackgroundColor:[UIColor whiteColor]];
    //     [whiteScreen setTag:999];
    //    [self.view bringSubviewToFront:circleView];
    full=false;
    [UIView beginAnimations:nil context:nil];
    //    [UIView setAnimationDuration:1.5];
    //    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];    
//    CGRect rect = CGRectMake(5,46,308,225);
//    [circleView setFrame:CGRectZero];
    mapView.frame = CGRectMake(0,46,320,216);
    btnFull.alpha = 1;
    btnMin.alpha = 0;
    [UIView commitAnimations];
    //    btnFull.hidden = YES;
}
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {

    NSString *a = [view.annotation title];
    for (int i =0; i < [pins count]; i++) {
        NSString *b = [[pins objectAtIndex:i] title];
        if([a isEqualToString:b]) {
            [tbl selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        }
    }
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[view.annotation title] message:[view.annotation description] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
//    [alert show];
//    MKCoordinateRegion reg = [mapView region];
//    reg.center = [view.annotation coordinate];
//    [mapView setRegion:reg];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // called when 'return' key pressed. return NO to ignore.
[textField resignFirstResponder];
    [googleLocalConnection getGoogleObjectsWithQuery:textField.text andMapRegion:[mapView region] andNumberOfResults:200 addressesOnly:YES andReferer:@"http://WWW.CHANGETHISTOYOURSITENAME.COM"];
    return YES;
}
- (void) googleLocalConnection:(GoogleLocalConnection *)conn didFinishLoadingWithGoogleLocalObjects:(NSMutableArray *)objects andViewPort:(MKCoordinateRegion)region
{
    if ([objects count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No matches found near this location" message:@"Try another place name or address (or move the map and try again)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    else {
        id userAnnotation=mapView.userLocation;
        [mapView removeAnnotations:mapView.annotations];
        [mapView addAnnotations:objects];
        pins = objects;
        if(userAnnotation!=nil)
			[mapView addAnnotation:userAnnotation];
        [mapView setRegion:region];
        [tbl reloadData];
    }
}

- (void) googleLocalConnection:(GoogleLocalConnection *)conn didFailWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error finding place - Try again" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [dm.contextCoreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *qp) {
        
    }disabled:^(NSError *err) {
    [dm.contextCoreConnector enableFromViewController:self success:nil failure:nil];
    }];
    double miles = 1;
    //    miles = 10 - miles;
    
    //    CLLocation *loc = [locationManager location];
    CLLocation *newLocation = mapView.userLocation.location;
    
    double scalingFactor = ABS( (cos(2 * M_PI * newLocation.coordinate.latitude / 360.0) ));
    
    
    MKCoordinateSpan span; 
    
    span.latitudeDelta = miles/69.0;
    span.longitudeDelta = miles/(scalingFactor * 69.0); 
    
    MKCoordinateRegion region;
    region.span = span;
    region.center = newLocation.coordinate;
    
    [mapView setRegion:region animated:YES];    
}
-(IBAction)refershMap {
    double miles = 20-slider.value+0.25;
    NSString *m=@"1 Mile";
    if(miles!=1) {
        m = [NSString stringWithFormat:@"%.0f Miles",miles];
    }
    txtMiles.text = m;
//    miles = 10 - miles;

//    CLLocation *loc = [locationManager location];
    CLLocation *newLocation = mapView.userLocation.location;
    
    double scalingFactor = ABS( (cos(2 * M_PI * newLocation.coordinate.latitude / 360.0) ));


    MKCoordinateSpan span; 
    
    span.latitudeDelta = miles/69.0;
    span.longitudeDelta = miles/(scalingFactor * 69.0); 
    
    MKCoordinateRegion region;
    region.span = span;
    region.center = newLocation.coordinate;
    
    [mapView setRegion:region animated:YES];
}
-(IBAction)showPermissions {
    [dm.contextCoreConnector showPermissionsFromViewController:self];
}
-(IBAction)search:(id)sender {
    [dm.contextCoreConnector enableFromViewController:self success:nil failure:^(NSError *err) {
        //show blank view
    }];  
}

- (IBAction)test
{
	[dm test];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIInterfaceOrientationIsPortrait(interfaceOrientation));
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [pins count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView 
                             dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell.
    GoogleLocalObject *av= [pins 
                        objectAtIndex: [indexPath row]];
    cell.textLabel.text = [av title]; 

    return cell;
}


@end
