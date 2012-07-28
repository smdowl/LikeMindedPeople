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
	// Do any additional setup after loading the view, typically from a nib.
    dm = [DataModel sharedInstance];
    locationManager = [[CLLocationManager alloc] init];    
    googleLocalConnection = [[GoogleLocalConnection alloc] initWithDelegate:self];

}
- (void)textFieldDidEndEditing:(UITextField *)textField {
[googleLocalConnection getGoogleObjectsWithQuery:textField.text andMapRegion:[mapView region] andNumberOfResults:4 addressesOnly:YES andReferer:@"http://mysuperiorsitechangethis.com"];

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
        if(userAnnotation!=nil)
            [mapView addAnnotation:userAnnotation];
        [mapView setRegion:region];
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
    double miles = slider.value;
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
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
