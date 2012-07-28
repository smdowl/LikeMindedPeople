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
//    [dm.contextCoreConnector checkStatusAndOnEnabled:nil disabled:^(NSError *err) {
        [dm.contextCoreConnector enableFromViewController:self success:nil failure:^(NSError *err) {
            //show blank view
        }];
//    }];
}
-(IBAction)updateRadius:(id)sender {
    MKCoordinateRegion region = [mapView region];
    
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
