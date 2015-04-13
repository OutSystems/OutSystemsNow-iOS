//
//  OSMobileECTController.h
//  OutsystemsMobileFrameworks
//
//  Created by engineering on 12/11/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#ifndef OutsystemsMobileFrameworks_OSMobileECTController_h
#define OutsystemsMobileFrameworks_OSMobileECTController_h

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OSMobileECTController : NSObject<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) NSString* hostname;

-(id)initWithSuperView:(UIView*)view andWebView:(UIWebView*)web forHostname:(NSString*)host;

-(void)prepareForViewDidLoad;
-(void)prepareForViewWillAppear;
-(void)prepareForUnload;

-(BOOL)isECTFeatureAvailable;

-(void)openECTView;
-(void)closeECTView;

-(void)onHelpTouch:(id)sender;
-(void)addHelperSingleTap:(id)target withSelector:(SEL)selector;
-(void)skipHelper:(BOOL)skip;

-(void)addOnExitEvent:(id)target withSelector:(SEL)selector;

-(void)onDrawingBegin:(CGPoint) point;
-(void)onDrawingUpdate:(CGPoint) point;
-(void)onDrawingEnd:(CGPoint) point;

@end


#endif
