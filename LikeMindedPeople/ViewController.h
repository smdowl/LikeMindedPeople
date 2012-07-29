//
//  ViewController.h
//  test
//
//  Created by Tyler Weitzman on 7/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "DataModel.h"
#import <CoreLocation/CoreLocation.h>
#import "GoogleLocalConnection.h"
@class GoogleLocalObject;
@class DataModel;
@interface ViewController : UIViewController<GoogleLocalConnectionDelegate> {
    IBOutlet UITextField *txtSearch;
    IBOutlet UISlider *slider;
    IBOutlet MKMapView *mapView;
    CLLocationManager *locationManager;
    GoogleLocalConnection *googleLocalConnection;    
    CLLocation *loc;
    DataModel *dm;
    int z;
}
-(IBAction)search:(id)sender;
-(IBAction)refershMap;
-(IBAction)showPermissions;
-(IBAction)test;
@end
