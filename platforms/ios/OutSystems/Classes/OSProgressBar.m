//
//  OSProgressBar.m
//  OutSystems
//
//  Created by engineering on 11/05/15.
//
//

#import "OSProgressBar.h"

float const kBarAnimationDuration = 0.27f;
float const kFadeAnimationDuration = 0.27f;
float const kOSProgressBarHeight = 3.0f;

@interface OSProgressBar()

@property float currentValue;
@property int checkPoint;
@property BOOL animationInProgress;
@property NSTimer *updateTimer;
@property (nonatomic, strong) UIView *progressBar;
@property (strong, nonatomic) NSLayoutConstraint* redBarWidthConstriant;

@end

@implementation OSProgressBar

-(id)initForView:(UIView*)view{
    self = [super initWithFrame:CGRectMake(0,0, 0, 0)];
    if(self){
        [view addSubview:self];
        
        // Initialization code
        [self initialization];
        
    }
    return self;
}


-(void)initialization{
    _currentValue = 0.0;
    _checkPoint = 5;
    _animationInProgress = NO;
    
    // White bar
    
    [self setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.75]];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.alpha = 0.0;
    
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    // Leading space to super view
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeLeading
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeLeading
                                                              multiplier:1.0
                                                                constant:0.0]];
    // Bottom space to super view
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.superview
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0
                                                                constant: 0]];
    
    
    // Equals width
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:1.0
                                                                constant:1.0]];
    
    // Progress bar height
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:0
                                                               multiplier:1.0
                                                                 constant: kOSProgressBarHeight]];
    
    
    // Red bar
    
    
    _progressBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [_progressBar setBackgroundColor:[UIColor colorWithRed:204.0/255.0 green:30.0/255.0 blue:21.0/255.0 alpha:1.0]];
    _progressBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [_progressBar.layer setCornerRadius:2.0f];
    
    [self addSubview:_progressBar];    
    
    [_progressBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    
    // Leading space to white bar
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressBar
                                                               attribute:NSLayoutAttributeLeading
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeLeading
                                                              multiplier:1.0
                                                                constant:0.0]];
    // Bottom space to white bar
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressBar
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0
                                                                constant: 0]];
    
    // Equals height
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressBar
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1.0
                                                      constant: 1.0]];
    
    
    // Red bar width
    
    _redBarWidthConstriant = [NSLayoutConstraint constraintWithItem:_progressBar
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:0
                                                         multiplier:1.0
                                                           constant:kOSProgressBarHeight];
    
    [_progressBar addConstraint:_redBarWidthConstriant];
    
    
}

-(void)setProgress:(float)progress animated:(BOOL)animated{
    BOOL isGrowing = progress > 0.0;

    [UIView animateWithDuration:(isGrowing && animated) ? kBarAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _redBarWidthConstriant.constant = (progress * self.bounds.size.width) + kOSProgressBarHeight;
        [self layoutIfNeeded];
        
    } completion:nil];
    
    if(progress >= 1.0){
        [UIView animateWithDuration:animated ? kFadeAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.alpha = 0.0;
            
        } completion:^(BOOL completed){
            _redBarWidthConstriant.constant =  0;
            [self layoutIfNeeded];
        }];
    }
    else{
        [UIView animateWithDuration:animated ? kFadeAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.alpha = 1.0;
        } completion:nil];
    }
}


-(void)updateProgress:(BOOL)animated{
    
    if (_currentValue >= 1.0){
        _currentValue = 0.0;
        self.alpha = 0.0;
        
    }
    else {
        if(_animationInProgress){
            
            if(_currentValue < 0.1){
                _currentValue = 0.1;
            }
            else
                if (_currentValue == 0.5 && _checkPoint > 0){
                    _checkPoint--;
                }
                else if(_currentValue + 0.1  < 0.9){
                    _currentValue += 0.1;
                }
            
            [self setProgress:_currentValue animated:YES];
            
            NSMutableDictionary *dict = [NSMutableDictionary new];
            [dict setObject:(animated ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0]) forKey:@"animated"];
            _updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateEvent:) userInfo:dict repeats:NO];
        }
    }
}

-(void)updateEvent:(NSNotification *)notification{
    NSMutableDictionary *dict = [notification observationInfo];
    NSNumber *animationValue = [dict valueForKey:@"animated"];
    BOOL animated = animationValue > 0;

    [self updateProgress:animated];
}

-(void)startProgress:(BOOL)animated{
    _animationInProgress = YES;
    _currentValue = 0.0;
    _checkPoint = 5;

    _redBarWidthConstriant.constant = 0;
    [self layoutIfNeeded];
    
    [self updateProgress:animated];
    
}


-(void)cancelProgress:(BOOL)animated{
    [self stopProgress:YES];
}


-(void)stopProgress:(BOOL)animated{
    [self setProgress:1.0 animated:animated];
    _animationInProgress = NO;
    [_updateTimer invalidate];
}


-(void)dealloc{

    if(_updateTimer){
        [_updateTimer invalidate];
    }
    
    [_progressBar removeFromSuperview];
    _progressBar = nil;
}


@end
