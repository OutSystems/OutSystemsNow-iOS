//
//  OSAlertView.h
//  OutSystems
//
//  Created by engineering on 06/11/14.
//
//

#ifndef OutSystems_OSAlertView_h
#define OutSystems_OSAlertView_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>



@protocol OSAlertViewDelegate

- (void)customOSdialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface OSAlertView : UIView<OSAlertViewDelegate>

@property (nonatomic, retain) UIView *dialogView;    // Dialog's container view
@property (nonatomic, retain) UIView *containerView; // Container within the dialog (place your ui elements here)

@property (nonatomic, assign) id<OSAlertViewDelegate> delegate;
@property (nonatomic, retain) NSArray *buttonTitles;
@property (nonatomic, assign) BOOL useMotionEffects;

@property (copy) void (^onButtonTouchUpInside)(OSAlertView *alertView, int buttonIndex) ;

- (id)init;

- (void)show;
- (void)close;

- (IBAction)customOSdialogButtonTouchUpInside:(id)sender;
- (void)setOnButtonTouchUpInside:(void (^)(OSAlertView *alertView, int buttonIndex))onButtonTouchUpInside;

@end

#endif
