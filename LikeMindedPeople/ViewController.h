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
#import "TDBadgedCell.h"
@class GoogleLocalObject;
@class DataModel;
@class TDBadgedCell;
@interface ViewController : UIViewController<GoogleLocalConnectionDelegate, MKMapViewDelegate, UITableViewDelegate,UITableViewDataSource, UIGestureRecognizerDelegate> {
    DataModel *dm; 
    CLLocationManager *locationManager;
    GoogleLocalConnection *googleLocalConnection;    
    CLLocation *loc;

    int selectedCategory;
    NSMutableArray *pins;

	IBOutlet UITableView *tbl;
    IBOutlet UIView *circleView;
    IBOutlet UIButton *btnFull;
    IBOutlet UIButton *btnMin;
    IBOutlet UIView *detailView;
    IBOutlet UIView *searchView;
	IBOutlet UITextField *txtSearch;
    IBOutlet UISlider *slider;
    IBOutlet MKMapView *mapView;
    IBOutlet UIButton *fbButton;
    IBOutlet UIViewController *fbLogin;
    IBOutlet UILabel *txtMiles;
	
    BOOL full;
}

@property (nonatomic, strong) IBOutlet UIViewController *fbLogin;
@property IBOutlet UIButton *fbButton;

-(IBAction)search:(id)sender;
-(IBAction)forceSearch;
-(IBAction)refershMap;
-(IBAction)showPermissions;
-(IBAction)category:(id)sender;
-(IBAction)fullScreen:(id)sender;
-(IBAction)minimize:(id)sender;
-(IBAction)back;
-(void)lookup:(NSString*)query;
-(void)setDetailView:(NSString*)title withDesc:(NSString*)desc andMatch:(NSString*)match andUsers:(NSString*)count andInterests:(NSString*)interests;

@end
