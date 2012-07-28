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
@class DataModel;
@interface ViewController : UIViewController {
    IBOutlet UITextField *txtSearch;
    IBOutlet UISlider *slider;
    IBOutlet MKMapView *mapView;
    DataModel *dm;
}
-(IBAction)search:(id)sender;
-(IBAction)updateRadius;
-(IBAction)showPermissions;
@end
