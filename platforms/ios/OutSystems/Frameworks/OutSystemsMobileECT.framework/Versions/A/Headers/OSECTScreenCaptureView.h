//
//  OSECTScreenCaptureView.h
//  OutsystemsMobileFrameworks
//
//  Created by engineering on 12/11/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#ifndef OutsystemsMobileFrameworks_OSECTScreenCaptureView_h
#define OutsystemsMobileFrameworks_OSECTScreenCaptureView_h

#import <UIKit/UIKit.h>
#import "OSECTUIView.h"

@interface OSECTScreenCaptureView : OSECTUIView

-(void)setScreenCapture:(UIImage*)image;
-(UIImage*)getScreenCapture;
-(void)resetScreenCapture;

-(void)addOnDrawingTarget:(id)target beginSelector:(SEL)beginSelector updateSelector:(SEL)updateSelector endSelector:(SEL)endSelector;

-(void)lockDrawings:(BOOL) lock;

@end

#endif
