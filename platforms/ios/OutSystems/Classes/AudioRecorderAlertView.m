//
//  AudioRecorderAlertView.m
//  OutSystems
//
//  Created by engineering on 06/11/14.
//
//

#import <Foundation/Foundation.h>
#import "AudioRecorderAlertView.h"

const static CGFloat kAudioRecorderAlertViewWidth   = 250;
const static CGFloat kAudioRecorderAlertViewHeight  = 100;
const static CGFloat kAudioRecorderAlertViewTimeout = 30;

const static int KAudioRecorderDoneAction   = 1; // button index


@interface AudioRecorderAlertView()


@property int durationTime;
@property BOOL firstLoad;
@property NSTimer *timer;

@property UILabel *timerLabel;
@property UIImage *microphoneImage;
@property UITextView *messageText;



@property id parent;
@property SEL onExitSelector;

@end



@implementation AudioRecorderAlertView

-(id)init{
    
    self = [super init];
    if(self){
        [self createContainer];
        [self createButtonTitles];
        self.durationTime = 0;
        self.firstLoad = YES;
    }
    
    return self;
}

-(id)initWithParent:(id)parent andSelector:(SEL)selector{
    self = [self init];
    if(self){
        self.parent = parent;
        self.onExitSelector = selector;
    }
    
    return self;
}


// Create Audio Recorder alert dialog's buttons
-(void)createButtonTitles{
    self.buttonTitles = @[@"Cancel",@"Done"];
}

// Create Audio Recorder Alert container
-(void)createContainer{
  
    UIView *audioRecorderView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                         0,
                                                                         kAudioRecorderAlertViewWidth,
                                                                         kAudioRecorderAlertViewHeight)];
    
    audioRecorderView.translatesAutoresizingMaskIntoConstraints = NO;
    [self setContainerView:audioRecorderView];
    
    
    CGRect frame = audioRecorderView.frame;
    CGFloat leftWidth = frame.size.width * 0.35;
    CGFloat rightWidth = frame.size.width * 0.65;
    
    // Create left view
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectZero];
    leftView.translatesAutoresizingMaskIntoConstraints = NO;
    [audioRecorderView addSubview:leftView];
    
    // Define width
    // Define width
    [leftView addConstraint:[NSLayoutConstraint constraintWithItem:leftView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:0
                                                         multiplier:1
                                                           constant:leftWidth]];
    
    // Define height
    [audioRecorderView addConstraint:[NSLayoutConstraint constraintWithItem:leftView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:audioRecorderView
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:frame.size.height]];
    
    
    // Top space to audio recorder view
    [audioRecorderView addConstraint:[NSLayoutConstraint constraintWithItem:leftView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:audioRecorderView
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:0.0]];

    // Leading space to audio recorder view
    [audioRecorderView addConstraint:[NSLayoutConstraint constraintWithItem:leftView
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:audioRecorderView
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1.0
                                                                   constant:0.0]];
    
 
    // Create right view
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectZero];
    rightView.translatesAutoresizingMaskIntoConstraints = NO;
    [audioRecorderView addSubview:rightView];
    
    
    // Define width
    [rightView addConstraint:[NSLayoutConstraint constraintWithItem:rightView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:0
                                                         multiplier:1
                                                           constant:rightWidth]];
    
    // Define height
    [rightView addConstraint:[NSLayoutConstraint constraintWithItem:rightView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:0
                                                         multiplier:1
                                                           constant:frame.size.height]];
    
    
    // Top space to audio recorder view
    [audioRecorderView addConstraint:[NSLayoutConstraint constraintWithItem:rightView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:audioRecorderView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    // Leading space to left view
    [audioRecorderView addConstraint:[NSLayoutConstraint constraintWithItem:rightView
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:leftView
                                                                  attribute:NSLayoutAttributeTrailing
                                                                 multiplier:1.0
                                                                   constant:0.0]];
    
    // Create icon view on the left view
    [self createIconView:leftView];
    
    // Create message view on the right view
    [self createMessageView:rightView];
    
   
}

-(void)createIconView:(UIView*)superView{
    
    CGRect frame = superView.frame;
    
    // Create microphone icon view
    self.microphoneImage = [UIImage imageNamed:@"icon_microphone_red"];
    UIImageView *recorderLogo = [[UIImageView alloc] initWithImage:self.microphoneImage];
    [superView addSubview:recorderLogo];
    [recorderLogo setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Top space to super view
    [superView addConstraint:[NSLayoutConstraint constraintWithItem:recorderLogo
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:30]];
    
    // Center horizontally
    [superView addConstraint:[NSLayoutConstraint constraintWithItem:recorderLogo
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    
    // Create timer view
    self.timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,frame.size.width*0.7, 20)];
    self.timerLabel.text = [NSString stringWithFormat:@"%ds", self.durationTime];
    [self.timerLabel setTextColor: [UIColor redColor]];
    [self.timerLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [self.timerLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [superView addSubview:self.timerLabel];
    
    // Top space to super view
    [superView addConstraint:[NSLayoutConstraint constraintWithItem:self.timerLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:recorderLogo
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:5]];
    
    // Center horizontally
    [superView addConstraint:[NSLayoutConstraint constraintWithItem:self.timerLabel
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
}

-(void)createMessageView:(UIView*)superView{
    
    // Create message view
    self.messageText = [[UITextView alloc] initWithFrame:CGRectZero];
    self.messageText.text = @"Your feedback is being recorded...";
    [self.messageText setTextColor:[UIColor blackColor]];
    [self.messageText setBackgroundColor:[UIColor clearColor]];
    [self.messageText setFont:[UIFont systemFontOfSize:16.0f]];
    [self.messageText setEditable:NO];
    [self.messageText setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.messageText sizeToFit];
    
    [superView addSubview:self.messageText];
    
    // Define width
    [superView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageText
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:0.9
                                                           constant:0]];
    
    [superView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageText
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:superView
                                                            attribute:NSLayoutAttributeHeight
                                                           multiplier:0.55
                                                             constant:0]];
    
    
    [superView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageText
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superView
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0]];

    [superView addConstraint:[NSLayoutConstraint constraintWithItem:self.messageText
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:superView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0
                                                           constant:0]];
    
}

-(void)show{
    [super show];
    if(self.firstLoad){
        self.firstLoad = YES;
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(updateDurationTime)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

-(void)updateDurationTime{
    self.durationTime += 1;
    self.timerLabel.text = [NSString stringWithFormat:@"%ds", self.durationTime];
    
    if(self.durationTime == kAudioRecorderAlertViewTimeout){
        [self.timer invalidate];
    
        BOOL recorded = YES;
        
        [self close];
        
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self.parent methodSignatureForSelector:self.onExitSelector]];
        [inv setSelector:self.onExitSelector];
        [inv setTarget:self.parent];
        [inv setArgument:&recorded atIndex:2];
        [inv invoke];
    }
}

// Default button behaviour
- (void)customOSdialogButtonTouchUpInside: (OSAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"AudioRecorderAlertView: Button Clicked! %d, %d", (int)buttonIndex, (int)[alertView tag]);

    BOOL recorded = NO;

    if(buttonIndex == KAudioRecorderDoneAction)
        recorded = YES;

    [self.timer invalidate];
    [self close];
    
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self.parent methodSignatureForSelector:self.onExitSelector]];
    [inv setSelector:self.onExitSelector];
    [inv setTarget:self.parent];
    [inv setArgument:&recorded atIndex:2];
    [inv invoke];

}

@end