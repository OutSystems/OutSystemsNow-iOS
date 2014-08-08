//
//  ApplicationViewController.h
//  HubApp
//
//  Created by engineering on 03/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Application.h"

typedef enum {
	OSAnimateTransitionDefault,
	OSAnimateTransitionSlideLeft,
	OSAnimateTransitionSlideRight,
	OSAnimateTransitionFadeOut
}OSAnimateTransition;

@interface ApplicationViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) Application* application;
@property BOOL isSingleApplication;

- (IBAction)navBack:(id)sender;
- (IBAction)navForward:(id)sender;
- (IBAction)navAppList:(id)sender;

@end
