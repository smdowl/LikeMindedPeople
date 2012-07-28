//
//  ViewController.m
//  test
//
//  Created by Tyler Weitzman on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    dm = [DataModel sharedInstance];
    locationManager = [[CLLocationManager alloc] init];    

}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [dm.contextCoreConnector checkStatusAndOnEnabled:^(QLContextConnectorPermissions *qp) {
        
    }disabled:^(NSError *err) {
    [dm.contextCoreConnector enableFromViewController:self success:nil failure:nil];
    }];
    
}
-(IBAction)refershMap {
    double miles = slider.value;
    

    CLLocation *newLocation = [locationManager location];
    
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
