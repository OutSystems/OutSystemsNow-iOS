//
//  OSNavigationBarAlert.m
//  OutSystems
//
//  Created by engineering on 09/02/15.
//
//

#import "OSNavigationBarAlert.h"

float const kOSNavigationBarHeight = 45;
float const kOSNavigationBarSlideTiming = 0.5;

@interface OSNavigationBarAlert()

@property (weak, nonatomic) NSLayoutConstraint *navbarTopSpaceConstraint;
@property (weak, nonatomic) NSLayoutConstraint *navbarHeightConstraint;
@property (retain, nonatomic) UILabel *messageLabel;
@property float defaultFontSize;

@end

@implementation OSNavigationBarAlert

-(id)init{
    
    self = [super init];
    
    if(self){
        self.backgroundColor = [UIColor colorWithRed:204.0/255.0 green:30.0/255.0 blue:21.0/255.0 alpha:1.0];
        self.defaultFontSize = 20.0f;
        self.messageText = @"OutSystems Now";
        
        // Check if the device is not an iPad
        if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad )
        {
            self.defaultFontSize = 14.0f;
        }
        [self setHidden:YES];
    }
    
    return self;
}


-(void)createView{

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];


    // Leading space to main view
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeLeading
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeLeading
                                                              multiplier:1.0
                                                                constant:0.0]];
    // Top space to main view
    
    _navbarTopSpaceConstraint =[NSLayoutConstraint constraintWithItem:self
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.superview
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0
                                                             constant: -kOSNavigationBarHeight];
    
    [self.superview addConstraint: _navbarTopSpaceConstraint];

    
    // Equals width
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:1.0
                                                                constant:0.0]];
    
    // Navigation bar height
    _navbarHeightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                           attribute:NSLayoutAttributeHeight
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:0
                                                          multiplier:1.0
                                                            constant: kOSNavigationBarHeight];
    
    [self addConstraint: _navbarHeightConstraint];

    [self createMessageSection];

}

-(void) createMessageSection{
    // Title
    self.messageLabel = [[UILabel alloc] init];
    [self.messageLabel setText:_messageText];
    [self.messageLabel setFont:[UIFont systemFontOfSize:_defaultFontSize]];
    [self.messageLabel setTextColor:[UIColor whiteColor]];
    
    
    [self.messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:_messageLabel];
    
    
    // Center X
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_messageLabel
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    // Center Y
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_messageLabel
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];
}

-(void)navigationBarHeightChange:(float)height{
    _navbarHeightConstraint.constant = height;
    [self layoutIfNeeded];
}

-(void)hideAlert:(BOOL)animated{
    
    if(animated){
        [UIView animateWithDuration:kOSNavigationBarSlideTiming
                              delay:0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _navbarTopSpaceConstraint.constant = -kOSNavigationBarHeight;
                             [self layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                             [self setHidden:YES];
                         }];
    }
    else{
        _navbarTopSpaceConstraint.constant = -kOSNavigationBarHeight;
        [self layoutIfNeeded];
        [self setHidden:YES];
    }

}

-(void)showAlert:(NSString*)message animated:(BOOL)animated;{

    if([message length] > 0)
        _messageLabel.text = message;
    else
        _messageLabel.text = @"OutSystems Now";
    
    [self setHidden:NO];

    
    if (animated){
        [UIView animateWithDuration:kOSNavigationBarSlideTiming
                              delay:0
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             _navbarTopSpaceConstraint.constant = 0;
                             [self layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                             
                         }];
        
    }else{
        _navbarTopSpaceConstraint.constant = 0;
        [self layoutIfNeeded];
    }

    
}


@end
