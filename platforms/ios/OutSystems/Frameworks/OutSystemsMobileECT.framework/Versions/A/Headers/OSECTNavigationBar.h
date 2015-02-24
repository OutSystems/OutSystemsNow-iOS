//
//  OSECTNavigationBar.h
//  OutSystemsMobileECTStaticLib
//
//  Created by engineering on 02/12/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#ifndef OutSystemsMobileECTStaticLib_OSECTNavigationBar_h
#define OutSystemsMobileECTStaticLib_OSECTNavigationBar_h

#import <UIKit/UIKit.h>
#import "OSECTUIView.h"

enum kOSECTNavigationBarActions{
    ectNavBarCloseECT,
    ectNavBarHelpECT,
};

@interface OSECTNavigationBar : OSECTUIView

-(void)moveBarToTop;
-(void)moveBarToOriginalPosition;

-(BOOL)isNearBy:(CGPoint) point;

-(void)addTarget:(id)target andSelector:(SEL)selector forAction:(enum kOSECTNavigationBarActions)action;

-(void)showButtons:(BOOL)show;


@end

#endif
