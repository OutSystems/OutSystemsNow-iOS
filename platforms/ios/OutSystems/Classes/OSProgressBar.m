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

@interface OSProgressBar()

@property float currentValue;
@property int checkPoint;
@property BOOL animationInProgress;
@property NSTimer *updateTimer;
@property (nonatomic, strong) UIView *progressBar;

@end

@implementation OSProgressBar

-(id)initWithFrame:(CGRect)frame{
   
    self = [super initWithFrame:frame];
    if (self) {
        
        
        // Initialization code
        [self initialization];

    }
    return self;

}


-(void)initialization{
    _currentValue = 0.0;
    _checkPoint = 5;
    _animationInProgress = NO;
    
    [self setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.75]];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.alpha = 0.0;
    
    CGRect frame = self.bounds;
    frame.size.width = 0;
    frame.origin.x -=5;
    
    _progressBar = [[UIView alloc] initWithFrame:frame];
    [_progressBar setBackgroundColor:[UIColor colorWithRed:204.0/255.0 green:30.0/255.0 blue:21.0/255.0 alpha:1.0]];
    _progressBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [_progressBar.layer setCornerRadius:2.0f];
    
    [self addSubview:_progressBar];
    
    [_progressBar.layer setShadowColor:[UIColor blackColor].CGColor];
    [_progressBar.layer setShadowOpacity:0.8];
    [_progressBar.layer setShadowRadius:3.0];
    [_progressBar.layer setShadowOffset:CGSizeMake(-2.0, -2.0)];
}

-(void)setProgress:(float)progress animated:(BOOL)animated{
    BOOL isGrowing = progress > 0.0;

    [UIView animateWithDuration:(isGrowing && animated) ? kBarAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGRect frame = _progressBar.frame;
        frame.size.width = (progress * self.bounds.size.width) + 5;
        _progressBar.frame = frame;
    } completion:nil];
    
    if(progress >= 1.0){
        [UIView animateWithDuration:animated ? kFadeAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.alpha = 0.0;
            
        } completion:^(BOOL completed){
            CGRect frame = self.frame;
            frame.size.width = 0;
            _progressBar.frame = frame;
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
    
    CGRect frame = self.bounds;
    frame.size.width = 0;
    frame.origin.x -=5;
    _progressBar.frame = frame;
    
    [self updateProgress:animated];
    
}


-(void)cancelProgress:(BOOL)animated{
    [_updateTimer invalidate];
}


-(void)stopProgress:(BOOL)animated{
    [self setProgress:1.0 animated:animated];
    _animationInProgress = NO;
}


-(void)dealloc{

    if(_updateTimer){
        [_updateTimer invalidate];
    }
    
    [_progressBar removeFromSuperview];
    _progressBar = nil;
}

@end
