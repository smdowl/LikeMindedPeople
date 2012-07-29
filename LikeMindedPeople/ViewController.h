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
@interface ViewController : UIViewController<GoogleLocalConnectionDelegate, MKMapViewDelegate, UITableViewDelegate,UITableViewDataSource> {
    IBOutlet UITextField *txtSearch;
    IBOutlet UISlider *slider;
    IBOutlet MKMapView *mapView;
    IBOutlet UIButton *fbButton;
    IBOutlet UIViewController *fbLogin;
    IBOutlet UILabel *txtMiles;
    CLLocationManager *locationManager;
    IBOutlet UIView *circleView;
    GoogleLocalConnection *googleLocalConnection;    
    CLLocation *loc;
    DataModel *dm;
    IBOutlet UITableView *tbl;
    int selectedCategory;
    NSMutableArray *pins;
    IBOutlet UIButton *btnFull;
    IBOutlet UIButton *btnMin;
}
@property (nonatomic, strong) IBOutlet UIViewController *fbLogin;
@property IBOutlet UIButton *fbButton;
-(IBAction)search:(id)sender;
-(IBAction)refershMap;
-(IBAction)showPermissions;
-(IBAction)category:(id)sender;
-(IBAction)fullScreen:(id)sender;
-(IBAction)minimize:(id)sender;

@end
