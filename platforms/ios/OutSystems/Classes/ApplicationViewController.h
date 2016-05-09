//
//  ApplicationViewController.h
//  HubApp
//
//  Created by engineering on 03/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Application.h"
#import "Infrastructure.h"
#import <OutSystemsMobileECT/OutSystemsMobileECT.h>

typedef enum {
	OSAnimateTransitionDefault,
	OSAnimateTransitionSlideLeft,
	OSAnimateTransitionSlideRight,
	OSAnimateTransitionFadeOut
}OSAnimateTransition;

@interface ApplicationViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) Application* application;
@property (strong, nonatomic) Infrastructure* infrastructure;
@property (strong, nonatomic) OSMobileECTController *mobileECTController;

@property BOOL isSingleApplication;

- (IBAction)navBack:(id)sender;
- (IBAction)navForward:(id)sender;
- (IBAction)navAppList:(id)sender;

@end
