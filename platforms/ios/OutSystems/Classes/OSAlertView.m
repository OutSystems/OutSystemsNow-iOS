//
//  OSAlertView.m
//  OutSystems
//
//  Created by engineering on 06/11/14.
//
//


#import "OSAlertView.h"

#import <QuartzCore/QuartzCore.h>

const static CGFloat kOSAlertViewDefaultButtonHeight       = 50;
const static CGFloat kOSAlertViewDefaultButtonSpacerHeight = 1;
const static CGFloat kOSAlertViewCornerRadius              = 7;
const static CGFloat kCustomIOS7MotionEffectExtent         = 10.0;

@implementation OSAlertView

CGFloat buttonHeight = 0;
CGFloat buttonSpacerHeight = 0;

@synthesize containerView, dialogView, onButtonTouchUpInside;
@synthesize delegate;
@synthesize buttonTitles;
@synthesize useMotionEffects;

- (id)init
{
    self = [super init];
    if (self) {
        
        [self initAlertView];
        
        delegate = self;
        useMotionEffects = false;
        buttonTitles = @[@"Cancel"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}


-(void)initAlertView{
    
    // Set view dimensions
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.autoresizesSubviews = YES;
    UIView *mainView = (UIView*)[[[UIApplication sharedApplication] windows] firstObject];
    [mainView addSubview:self];
    
    
    // Leading space to main view
    [mainView addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeLeading
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:mainView
                                                         attribute:NSLayoutAttributeLeading
                                                        multiplier:1.0
                                                          constant:0.0]];
    // Top space to main view
    [mainView addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:mainView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant: 0.0]];
    
    // Equals width
    [mainView addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:mainView
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0
                                                          constant:0.0]];
    
    // Equals height
    [mainView addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:mainView
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1.0
                                                          constant:0.0]];
}


// Create the dialog view, and animate opening the dialog
- (void)show
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

    // Fix autolayout for iOS7 or earlier
    if(iOSVersion < 8)
        [self rotateToInterfaceOrientation:NO];
    
    if (containerView == NULL) {
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    }
    
    // Create dialog view
    [self createDialogView];
    
    CGRect frame = self.dialogView.frame;
    
    // Add the custom container if there is any
    [dialogView addSubview:containerView];
    
    // Leading space to main view
    [dialogView addConstraint:[NSLayoutConstraint constraintWithItem:containerView
                                                         attribute:NSLayoutAttributeLeading
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:dialogView
                                                         attribute:NSLayoutAttributeLeading
                                                        multiplier:1.0
                                                          constant:0.0]];
    // Top space to main view
    [dialogView addConstraint:[NSLayoutConstraint constraintWithItem:containerView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:dialogView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant: 0.0]];
    
    
    dialogView.layer.shouldRasterize = YES;
    dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
#if (defined(__IPHONE_7_0))
    if (useMotionEffects) {
        [self applyMotionEffects];
    }
#endif
    
    dialogView.layer.opacity = 0.5f;
    dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);
    
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         dialogView.layer.opacity = 1.0f;
                         dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
                     }
                     completion:NULL
     ];
}

// Button has been touched
- (IBAction)customOSdialogButtonTouchUpInside:(id)sender
{
    if (delegate != NULL) {
        [delegate customOSdialogButtonTouchUpInside:self clickedButtonAtIndex:[sender tag]];
    }
    
    if (onButtonTouchUpInside != NULL) {
        onButtonTouchUpInside(self, (int)[sender tag]);
    }
}

// Default button behaviour
- (void)customOSdialogButtonTouchUpInside: (OSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button Clicked! %d, %d", (int)buttonIndex, (int)[alertView tag]);
    [self close];
}

// Dialog close animation then cleaning and removing the view from the parent
- (void)close
{
    CATransform3D currentTransform = dialogView.layer.transform;
    
    CGFloat startRotation = [[dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);
    
    dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    dialogView.layer.opacity = 1.0f;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
                         dialogView.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         for (UIView *v in [self subviews]) {
                             [v removeFromSuperview];
                         }
                         [self removeFromSuperview];
                     }
     ];
}

- (void)setSubView: (UIView *)subView
{
    containerView = subView;
}

// Creates the container view here: create the dialog, then add the custom content and buttons
- (void)createDialogView
{
    
    if ([buttonTitles count] > 0) {
        buttonHeight       = kOSAlertViewDefaultButtonHeight;
        buttonSpacerHeight = kOSAlertViewDefaultButtonSpacerHeight;
    } else {
        buttonHeight = 0;
        buttonSpacerHeight = 0;
    }
    
    
    CGFloat dialogWidth = containerView.frame.size.width;
    CGFloat dialogHeight = containerView.frame.size.height + buttonHeight + buttonSpacerHeight;
    
    CGSize dialogSize = CGSizeMake(dialogWidth, dialogHeight);
    
    
    UIView *dialogContainer =[[UIView alloc] initWithFrame:CGRectMake(0,0, 0, 0)];
    [dialogContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.dialogView = dialogContainer;
    [self addSubview:dialogView];
    
    // Define width
    [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:dialogContainer
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:0
                                                    multiplier:1.0
                                                      constant:dialogSize.width]];
    
    
    // Define height
    [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:dialogContainer
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:0
                                                               multiplier:1.0
                                                                 constant:dialogSize.height]];
    
    
    
    // Center horizontally
    [self addConstraint:[NSLayoutConstraint constraintWithItem:dialogContainer
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    // Center vertically
    [self addConstraint:[NSLayoutConstraint constraintWithItem:dialogContainer
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [dialogContainer setBackgroundColor:[UIColor colorWithRed:247.0 green:247.0 blue:247.0 alpha:1.0f]];
    [dialogContainer setOpaque:YES];
    
    CGFloat cornerRadius = kOSAlertViewCornerRadius;
    
    dialogContainer.layer.cornerRadius = cornerRadius;
    dialogContainer.layer.borderColor = [[UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f] CGColor];
    dialogContainer.layer.borderWidth = 1;
    dialogContainer.layer.shadowRadius = cornerRadius + 5;
    dialogContainer.layer.shadowOpacity = 0.1f;
    dialogContainer.layer.shadowOffset = CGSizeMake(0 - (cornerRadius+5)/2, 0 - (cornerRadius+5)/2);
    dialogContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    dialogContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:dialogContainer.bounds cornerRadius:dialogContainer.layer.cornerRadius].CGPath;
    
    // There is a line above the buttons
    UIView* lineView = [[UIView alloc] initWithFrame:CGRectZero];
    lineView.translatesAutoresizingMaskIntoConstraints = NO;
    [dialogContainer addSubview:lineView];
    
    // Horizontal: align center
    [dialogContainer addConstraint: [NSLayoutConstraint constraintWithItem:lineView
                                                                 attribute: NSLayoutAttributeCenterX
                                                                 relatedBy: NSLayoutRelationEqual
                                                                    toItem: dialogContainer
                                                                 attribute: NSLayoutAttributeCenterX
                                                                multiplier: 1
                                                                  constant: 0]];
    
    
    
    
    // Define height
    [lineView addConstraint:[NSLayoutConstraint constraintWithItem:lineView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:0
                                                               multiplier:1.0
                                                                 constant:buttonSpacerHeight]];
    
    
    // Leading space to dialog
    [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:lineView
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:dialogContainer
                                                                attribute:NSLayoutAttributeLeading
                                                               multiplier:1.0
                                                                 constant:0.0]];
    // Bottom space to dialog
    [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:lineView
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:dialogContainer
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant: 0.0-buttonHeight - buttonSpacerHeight]];
    
    lineView.backgroundColor =  [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
    
    [dialogContainer layoutIfNeeded];
    
    // Add the buttons too
    CGFloat buttonWidth = (dialogContainer.bounds.size.width / [buttonTitles count]) - 0.5f;
    
    for (int i=0; i<[buttonTitles count]; i++) {
        
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [closeButton addTarget:self action:@selector(customOSdialogButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTag:i];
        
        [closeButton setTitle:[buttonTitles objectAtIndex:i] forState:UIControlStateNormal];
        [closeButton setTitle:[buttonTitles objectAtIndex:i] forState:UIControlStateHighlighted];
        
        [closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [closeButton.layer setCornerRadius:kOSAlertViewCornerRadius];
        
        if(i+1== [buttonTitles count]){
            [closeButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
        }
        [closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [dialogContainer addSubview:closeButton];
        
        // Define width
        [closeButton addConstraint:[NSLayoutConstraint constraintWithItem:closeButton
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:0
                                                                   multiplier:1.0
                                                                     constant:buttonWidth]];
        
        
        // Define height
        [closeButton addConstraint:[NSLayoutConstraint constraintWithItem:closeButton
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:0
                                                               multiplier:1.0
                                                                 constant:buttonHeight]];
        
        // Leading space to dialog
        [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:closeButton
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:dialogContainer
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:i * buttonWidth + (i > 0 ? 1.0f : 0.0f)]];
        // Bottom space to dialog
        [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:closeButton
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:dialogContainer
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant: 0.0]];
        
        [closeButton layoutIfNeeded];
        
        if(i+1 < [buttonTitles count]){
            // Add button separator
            UIView *separator = [[UIView alloc] initWithFrame:CGRectZero];
            separator.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
            [separator setTranslatesAutoresizingMaskIntoConstraints:NO];
            [dialogContainer addSubview:separator];
            
            // Define width
            [separator addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                                       [NSString stringWithFormat:@"H:[separator(==%f)]", buttonSpacerHeight]
                                                                              options:0
                                                                              metrics:nil
                                                                                views:NSDictionaryOfVariableBindings(separator)]];
            
            // Define height
            [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:separator
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:closeButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant: 0.0]];
            
            // Leading space to button
            [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:separator
                                                                        attribute:NSLayoutAttributeLeading
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:closeButton
                                                                        attribute:NSLayoutAttributeTrailing
                                                                       multiplier:1.0
                                                                         constant: 0.0]];
            
            // Bottom space to dialog
            [dialogContainer addConstraint:[NSLayoutConstraint constraintWithItem:separator
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:dialogContainer
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                         constant: 0.0]];
            
        }
    }
    
}


#if (defined(__IPHONE_7_0))
// Add motion effects
- (void)applyMotionEffects {
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }
    
    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);
    
    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);
    
    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];
    
    [dialogView addMotionEffect:motionEffectGroup];
}
#endif


-(void)updateConstraints{
    [super updateConstraints];
    
    if(self.dialogView)
        [self.dialogView updateConstraints];

    if(self.containerView)
        [self.containerView updateConstraints];
}

-(void)rotateToInterfaceOrientation:(BOOL)animate{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
   
    if(animate){
        
        
        CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
        CGAffineTransform rotation;
        
        switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
                break;
                
            default:
                rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
                break;
        }
        
        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             dialogView.transform = rotation;
                         }
                         completion:^(BOOL finished){
                             // fix errors caused by being rotated one too many times
                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                 UIInterfaceOrientation endInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
                                 if (interfaceOrientation != endInterfaceOrientation) {
                                     // TODO user moved phone again before than animation ended: rotation animation can introduce errors here
                                 }
                             });
                         }
         ];
    }
    
    else{
        
        switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                break;
                
            default:
                break;
        }
        
        
    }
    
}

// Handle device orientation changes
- (void)deviceOrientationDidChange: (NSNotification *)notification{

    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    // Fix autolayout for iOS7 or earlier
    if(iOSVersion < 8)
        [self rotateToInterfaceOrientation:YES];
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

@end