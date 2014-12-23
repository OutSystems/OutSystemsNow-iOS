//
//  OSECTHelperView.h
//  OutsystemsMobileFrameworks
//
//  Created by engineering on 12/11/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#ifndef OutsystemsMobileFrameworks_OSECTHelperView_h
#define OutsystemsMobileFrameworks_OSECTHelperView_h

#import <UIKit/UIKit.h>
#import "OSECTUIView.h"

@interface OSECTHelperView : OSECTUIView

-(void)calculateECTHelperImage:(UIInterfaceOrientation)toInterfaceOrientation;
-(void)addSingleTap:(id)target withSelector:(SEL)selector;

-(void) openHelperView;
-(void)closeHelperView;

- (void)onTapped:(UIGestureRecognizer *)gestureRecognizer;

@end


#endif
