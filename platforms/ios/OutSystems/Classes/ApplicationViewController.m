//
//  ApplicationViewController.m
//  HubApp
//
//  Created by engineering on 03/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import "ApplicationViewController.h"
#import "CDVViewController.h"
#import "PXRImageSizeUtil.h"
#import <Crashlytics/Crashlytics.h>
#import "MobileECT.h"
#import "CanvasView.h"
#import "OSNavigationController.h"
#import "AudioRecorderAlertView.h"
#import "ECTApi.h"

// The predefined header height of the OutSystems App. Will be used for animations
uint const OSAPP_FIXED_MENU_HEIGHT = 0;
float const ECT_TOOLBAR_HEIGHT = 45;

float const IPHONE5_HEIGHT = 568;
float const IPHONE6_HEIGHT = 667;
float const IPAD_HEIGHT = 1024;

// Mobile ECT POST fields
NSString* const kECTFeedbackMessage = @"Message";
NSString* const kECTFeedbackEnvironmentUID = @"EnvironmentUID";
NSString* const kECTFeedbackEspaceUID = @"EspaceUID";
NSString* const kECTFeedbackApplicationUID = @"ApplicationUID";
NSString* const kECTFeedbackScreenUID = @"ScreenUID";
NSString* const kECTFeedbackScreenName = @"ScreenName";
NSString* const kECTFeedbackUserId = @"UserId";
NSString* const kECTFeedbackViewportWidth = @"ViewportWidth";
NSString* const kECTFeedbackViewportHeight = @"ViewportHeight";
NSString* const kECTFeedbackUserAgentHeader = @"UserAgentHeader";
NSString* const kECTFeedbackRequestURL = @"RequestURL";
NSString* const kECTFeedbackSoundMessageBase64 = @"FeedbackSoundMessageBase64";
NSString* const kECTFeedbackSoundMessageMimeType = @"FeedbackSoundMessageMimeType";
NSString* const kECTFeedbackScreenshotBase64 = @"FeedbackScreenshotBase64";
NSString* const kECTFeedbackScreenshotMimeType = @"FeedbackScreenshotMimeType";

// JavaScript API
NSString* const kECTJSEnvironmentUID = @"outsystems.api.requestInfo.getEnvironmentKey()";
NSString* const kECTJSEspaceUID = @"outsystems.api.requestInfo.getEspaceKey()";
NSString* const kECTJSApplicationUID = @"outsystems.api.requestInfo.getApplicationKey()";
NSString* const kECTJSScreenUID = @"outsystems.api.requestInfo.getWebScreenKey()";
NSString* const kECTJSScreenName = @"outsystems.api.requestInfo.getWebScreenName()";
NSString* const kECTJSUserId = @"ECT_JavasScript.userId";
NSString* const kECTJSUserAgentHeader = @"navigator.userAgent";
NSString* const kECTJSSupportedApiVersions = @"ECT_JavaScript.supportedApiVersions";

// Mobile ECT Types
NSString* const kECTAudioMimeType = @"audio/mp3";
NSString* const kECTImageMimeType = @"image/jpeg";

NSString* const kECTStatusSending = @"Sending your feedback...";
NSString* const kECTStatusFailed = @"Failed to send your feedback.";

NSString* const kECTSupportedApiVersion = @"1.0.0";


@interface ApplicationViewController ()
@property (strong, nonatomic) CDVViewController *applicationBrowser;

@property (weak, nonatomic) IBOutlet UIView *webViewFullScreen;
@property (nonatomic) bool firstLoad;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *applicationListButton;

@property (nonatomic) OSAnimateTransition selectedTransition;

// The parent container view of all the animations on top of the webview
@property (weak, nonatomic) IBOutlet UIView *loadingView;
// Holds the copy of the current screen that will be faded out into the new screen
@property (weak, nonatomic) IBOutlet UIImageView *webViewImageLoading;
// Holds a copy of the static part of the current screen, that will remain visible while a sliding animation occurs
@property (strong, nonatomic) UIImageView *webViewStaticImageLoading;

@property (nonatomic) CGFloat lastContentOffset;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navBack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navForward;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navAppList;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navSettings;

@property BOOL viewFinishedLoad;
@property (weak, nonatomic) IBOutlet UIView *loadingProgressView;

// Mobile ECT
@property (weak, nonatomic) IBOutlet UIView *mobileECTView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *openMobileECTButton;
@property (weak, nonatomic) IBOutlet UIView *ectHelperView;
@property (weak, nonatomic) IBOutlet UIView *ectToolbarView;
@property (weak, nonatomic) IBOutlet UIImageView *ectHelperImageView;
@property (weak, nonatomic) IBOutlet UITextView *ectTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ectToolbarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ectToolbarBottomConstraint;
@property (weak, nonatomic) IBOutlet CanvasView *ectScreenCaptureView;
@property (weak, nonatomic) IBOutlet UIView *ectStatusView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ectActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *ectStatusMessage;
@property (weak, nonatomic) IBOutlet UIButton *ectRetryButton;
@property (weak, nonatomic) IBOutlet UIButton *ectCancelRetryButton;
@property (weak, nonatomic) IBOutlet UIButton *ectSendFeedbackButton;
@property (weak, nonatomic) IBOutlet UIButton *ectMicrophoneButton;
@property (weak, nonatomic) IBOutlet UIButton *ectPlayAudioButton;


@property (strong,nonatomic) NSNumber* previousECTToolbarHeight;
@property (retain,nonatomic) NSMutableArray* originalToolbarItems;
@property (retain, nonatomic) NSMutableArray *ectSupportedApiVersions;

@property AVAudioRecorder *recorder;
@property AVAudioPlayer *player;
@property BOOL hasAudioComments;
@property BOOL ectSubmissionFailed;
@property BOOL ectAvailabilityChecked;

@end

@implementation ApplicationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set custom user agent
    UIWebView* tempWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString* userAgent = [tempWebView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    
    // Get the native app version and append it to user agent.
    NSString *nativeAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    userAgent = [userAgent stringByAppendingString: [NSString stringWithFormat:@" OutSystemsApp v.%@", nativeAppVersion]];
    
    // Store the full user agent in NSUserDefaults to be used by real web view.
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:userAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

    
    // Do any additional setup after loading the view.
    self.applicationBrowser = [CDVViewController new];
  
    self.applicationBrowser.startPage = _application.path;
    self.applicationBrowser.wwwFolderName = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewDidStartLoad:)
                                                 name:@"CDVPluginResetNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewDidFinishLoad:)
                                                 name:@"CDVPageDidLoadNotification"
                                               object:nil];
    
    self.firstLoad = YES;
    
    self.applicationBrowser.view.frame = self.webViewFullScreen.frame;
    
    [self addChildViewController:self.applicationBrowser];
    [self.webViewFullScreen addSubview:self.applicationBrowser.view];
    
    // remove bounce effect
    self.applicationBrowser.webView.scrollView.bounces = NO;
    
    // Hide Mobile ECT button
    self.originalToolbarItems = [self.toolbarItems mutableCopy];
    NSMutableArray *toolbarButtons = [self.toolbarItems mutableCopy];
    [toolbarButtons removeObject:self.openMobileECTButton];
    [self setToolbarItems:toolbarButtons animated:YES];
    
    // Mobile ECT Configurations
    self.ectTextView.delegate = self;
    
    [[self.ectTextView layer] setCornerRadius:5];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
  
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onECTHelperTaped:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    
    [self.ectHelperImageView addGestureRecognizer:singleTap];
    [self.ectHelperImageView setUserInteractionEnabled:YES];
    
    self.ectScreenCaptureView.hidden = YES;
    self.ectStatusView.hidden = YES;
    
    self.previousECTToolbarHeight = [NSNumber numberWithFloat:self.ectToolbarHeightConstraint.constant];
    
    [self initAudioRecorder];

    [self showTextAreaOrPlayButton];
    
    self.ectSupportedApiVersions = [[NSMutableArray alloc]init];
    self.ectAvailabilityChecked = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbar.hidden = NO;
    self.navigationController.navigationBar.hidden = YES;
    
    self.applicationBrowser.webView.scalesPageToFit = YES;
    [self.applicationBrowser setStartPage:_application.path];
    
    self.lastContentOffset = 0;
    
    self.loadingView.hidden = YES;
    
    self.mobileECTView.hidden = YES;
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController unlockInterfaceOrientation];

}

- (void)viewDidAppear:(BOOL)animated{
    if(self.viewFinishedLoad == YES && self.loadingView.hidden==NO){
        self.loadingView.hidden= YES;
    }
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (IBAction)navBack:(id)sender {
    if ([self.applicationBrowser.webView canGoBack]) {
        [self.applicationBrowser.webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)navForward:(id)sender {
    if ([self.applicationBrowser.webView canGoForward]) {
        [self.applicationBrowser.webView goForward];
    }
}

- (IBAction)navAppList:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) loadingTimer{
    self.loadingProgressView.hidden = NO;
}

# pragma mark - Web View

// This is not working as CDVWebViewDelegate is receiving this events
-(void)webViewDidStartLoad:(NSNotification *) notification {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if(self.firstLoad) {
        self.applicationBrowser.view.hidden = YES;
    }
    
    self.viewFinishedLoad = NO;
    
    OSAnimateTransition animateTransition = self.selectedTransition == OSAnimateTransitionDefault ? OSAnimateTransitionFadeOut : self.selectedTransition;
    [self transitionPrepareAnimation: animateTransition];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadingTimer) userInfo:nil repeats:NO];
    
}



// This is not working as CDVWebViewDelegate is receiving this events
-(void)webViewDidFinishLoad:(NSNotification *) notification {
    if(self.firstLoad) {
        self.firstLoad = NO;
        self.applicationBrowser.view.hidden = NO;
    }
    
    if ([self.applicationBrowser.webView canGoForward]) {
        self.navForward.enabled = YES;
    } else {
        self.navForward.enabled = NO;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // capture the scroll events to hide / unhide the toolbar
    self.applicationBrowser.webView.scrollView.delegate = self;

    [self transitionToNewPage];
    
    self.viewFinishedLoad = YES;
    
    // Check if Mobile ECT is enable for the app
    if(self.ectAvailabilityChecked == NO && [self isECTAvailable])
        [self setToolbarItems:self.originalToolbarItems animated:YES];
    
}

-(void)transitionPrepareAnimation:(OSAnimateTransition) animateTransition {
	
    self.loadingProgressView.hidden = YES;
    
    if(self.firstLoad == NO) {
        UIImage *viewImage = [self captureCurrentWebPage];
        self.webViewImageLoading.image = viewImage;
	
        // If we will be sliding, get the snapshot for the fixed section (e.g. menu) visible
        if(animateTransition != OSAnimateTransitionFadeOut) {
            CGRect cropRect = CGRectMake(0, 0, viewImage.size.width, OSAPP_FIXED_MENU_HEIGHT);
            if(!self.webViewStaticImageLoading) {
                self.webViewStaticImageLoading = [[UIImageView alloc] initWithFrame:cropRect];
                self.webViewStaticImageLoading.contentMode = UIViewContentModeScaleToFill;
                [self.loadingView.superview addSubview:self.webViewStaticImageLoading];
            }
            
            self.webViewStaticImageLoading.image = [PXRImageSizeUtil crop:viewImage
                                                                 withSize:CGSizeMake(cropRect.size.width, cropRect.size.height)
                                                            alignVertical:PXRImageSizeUtilVerticalAlignTop
                                                            andHorizontal:PXRImageSizeUtilHorizontalAlignLeft];;
            self.webViewStaticImageLoading.hidden = NO;
        }
	}
	
	// Make the loading view animations visible
	self.loadingView.alpha = 1;
	self.loadingView.hidden = NO;
    
}



-(void)transitionToNewPage {
	
	if(self.selectedTransition == OSAnimateTransitionFadeOut || self.selectedTransition == OSAnimateTransitionDefault) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5];
		
		// Fade it out to the new page
		self.loadingView.alpha = 0;
		self.webViewStaticImageLoading.hidden = YES;
		
		[UIView commitAnimations];
		
	} else {		// slide left or slide right
		
		float width = self.loadingView.frame.size.width;
		float height = self.loadingView.frame.size.height;
		float offset = self.selectedTransition == OSAnimateTransitionSlideRight ? width*2 : -width;
		
		[UIView animateWithDuration:0.33f
							  delay:0.0f
							options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
						 animations:^{
							 [self.loadingView setFrame:CGRectMake(offset, 0.0, width, height)];
						 }
						 completion:^(BOOL finished){
							 self.loadingView.alpha = 0;
							 [self.loadingView setFrame:CGRectMake(0.0, 0.0, width, height)];
							 self.webViewStaticImageLoading.hidden = YES;
						 }];
		
	}
	
	// reset to default transition
	self.selectedTransition = OSAnimateTransitionDefault;
	
}


-(UIImage*)captureCurrentWebPage{
    // Capture the current page in an image and render it on the view
    // that will sit over the webview
    UIGraphicsBeginImageContextWithOptions(self.applicationBrowser.view.bounds.size,
                                           self.applicationBrowser.view.opaque,
                                           0.0);
    [self.applicationBrowser.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}

# pragma mark - ECT Feedback Text

- (void)keyboardWillShown:(NSNotification*)aNotification
{
    CGRect frame = [aNotification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    float dY = CGRectGetHeight(self.view.frame)-newFrame.origin.y;
    
    self.ectToolbarBottomConstraint.constant = dY;
    [self.view layoutIfNeeded];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    self.ectToolbarBottomConstraint.constant = 0;
    [self.view layoutIfNeeded];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    // ECT message limit
    return [[textView text] length] - range.length + text.length < 500;
}


-(void)textViewDidBeginEditing:(UITextView *)textView{
    
    if(self.ectHelperView.hidden == NO)
        [self onECTHelperTaped:nil];
    
    if(textView.textColor==[UIColor grayColor]){
        textView.textColor=[UIColor blackColor];
        textView.text=@"";
    }

    
}

- (void)textViewDidChange:(UITextView *)textView{

    CGRect frame = textView.frame;
    CGSize sizeThatFitsTextView = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)];
    
    float dY = sizeThatFitsTextView.height - frame.size.height;
    
    if([textView.text length] > 0){
        // Hide microphone button
        self.ectMicrophoneButton.hidden = YES;
        self.ectSendFeedbackButton.hidden= NO;
    }
    else{
        // Show microphone button
        self.ectMicrophoneButton.hidden = NO;
        self.ectSendFeedbackButton.hidden= YES;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    
    if(dY != 0 && sizeThatFitsTextView.height >= 33 && sizeThatFitsTextView.height <= 200){
        

        
        [UIView animateWithDuration:0.2 animations:^{
        self.ectToolbarHeightConstraint.constant += dY;
            [self.view layoutIfNeeded];
        }];
        
        
    }

}

# pragma mark - ECT Feedback Audio
- (IBAction)onPlayECTAudio:(id)sender {
    [self playRecordedAudio];
}

- (void)onAudioRecorderExit:(BOOL)recorded{
    [self stopRecording];
    
    if(recorded){
        self.hasAudioComments = YES;
    }
    else{
        [self deleteRecording];
    }

    [self showTextAreaOrPlayButton];
}



#pragma mark - Audio Recorder

-(void)initAudioRecorder{
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"ECTAudioComment.aac",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
}

-(void)startRecording{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    
    // Start recording
    [self.recorder record];
    
}

-(void)stopRecording{
    [self.recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
}


-(void)playRecordedAudio{
    if (![self.recorder isRecording]){
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recorder.url error:nil];
        [self.player setDelegate:self];
        [self.player play];
    }
}

-(void)deleteRecording{
    if([self.player isPlaying]){
        [self.player stop];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.recorder.url.path]) {
        if (![self.recorder deleteRecording])
            NSLog(@"Failed to delete %@", self.recorder.url);
    }
    
    self.hasAudioComments = NO;
}

#pragma mark - AVAudioRecorderDelegate

- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    NSLog(@"Finish recording...");
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"Finish playing...");
}


#pragma mark - Mobile ECT Features

-(BOOL)isECTAvailable{
    self.ectAvailabilityChecked = YES;
    
    NSString *expr = @"typeof ECT_JavaScript != 'undefined'";
    
    BOOL ectAvailable = [[self.applicationBrowser.webView stringByEvaluatingJavaScriptFromString:expr] boolValue];
    
    if(ectAvailable && [self getECTApiInfo]){
        // check compatibility with OSNow - Mobile ECT
        ectAvailable = [self checkECTCompatibility];
    }
    return ectAvailable;
    
}

-(BOOL)getECTApiInfo{
    [self.ectSupportedApiVersions removeAllObjects];
    
    int numOfAPIs = [[self getECTJSValue:[NSString stringWithFormat:@"%@.length",kECTJSSupportedApiVersions]] intValue];
    
    for(int i = 0; i<numOfAPIs; i++){
        NSString *accessor = [NSString stringWithFormat:@"%@[%i]",kECTJSSupportedApiVersions,i];
        NSString *apiVersion = [self getECTJSValue: [accessor stringByAppendingString:@".ApiVersion"] ];
        NSString *apiURL = [self getECTJSValue: [accessor stringByAppendingString:@".URL"] ];
        BOOL apiCurrentVersion = [[self getECTJSValue: [accessor stringByAppendingString:@".IsCurrentVersion"] ] boolValue];
        
        ECTApi *api = [[ECTApi alloc] initWithVersion:apiVersion url:apiURL current:apiCurrentVersion];
        [self.ectSupportedApiVersions addObject:api];
        
        NSLog(@"ECTApi: %@",api);
    }
    
    NSArray *sortedArray = [self.ectSupportedApiVersions sortedArrayUsingComparator:^NSComparisonResult(ECTApi *e1, ECTApi *e2){
        return [e1 compare:e2];
    }];
    
    self.ectSupportedApiVersions = [NSMutableArray arrayWithArray:sortedArray];
    
    
    return numOfAPIs > 0;
}

-(BOOL)checkECTCompatibility{

    NSMutableArray * supportedVersions = [[NSMutableArray alloc] init];
    
    for(int i=0; i< [self.ectSupportedApiVersions count]; i++){
        ECTApi* api = self.ectSupportedApiVersions[i];
        BOOL compatible = [api isCompatibleWithVersion:kECTSupportedApiVersion];
        if(compatible){
            [supportedVersions addObject:api];
            break;
        }
    }
    
    [self.ectSupportedApiVersions removeAllObjects];
    self.ectSupportedApiVersions = supportedVersions;
    
    return [self.ectSupportedApiVersions count] > 0;
}

- (IBAction)onOpenECT:(id)sender {
    [self openECTView];
}

- (IBAction)onCloseECT:(id)sender {
    if(self.ectHelperView.hidden == NO)
        [self onECTHelperTaped:nil];
    else
        [self closeECTView];
}
- (IBAction)onSendECT:(id)sender {
    
    self.ectActivityIndicator.hidden = NO;
    self.ectStatusMessage.text = kECTStatusSending;
    self.ectRetryButton.hidden = YES;
    self.ectCancelRetryButton.hidden = YES;
    self.ectStatusView.hidden = NO;
    
    self.previousECTToolbarHeight = [NSNumber numberWithFloat:self.ectToolbarHeightConstraint.constant];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.ectToolbarHeightConstraint.constant = ECT_TOOLBAR_HEIGHT;
        [self.view layoutIfNeeded];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendECTFeedback) userInfo:nil repeats:NO];
    
}

- (IBAction)onCancelRetry:(id)sender {
    self.ectStatusView.hidden = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.ectToolbarHeightConstraint.constant = [self.previousECTToolbarHeight floatValue];
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)onRecordComment:(id)sender {
    [self.view endEditing:YES];
    
    if(self.ectHelperView.hidden == NO)
        [self onECTHelperTaped:nil];
    
    AudioRecorderAlertView *alert = [[AudioRecorderAlertView alloc] initWithParent:self andSelector:@selector(onAudioRecorderExit:)];
    [alert show];
    
    [self startRecording];
}


-(void)openECTView{
    // Hide navigation toolbar
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    // Capture the current web page
    UIImage *viewImage = [self captureCurrentWebPage];
    [self.ectScreenCaptureView setBackgroundImage:viewImage];
    self.ectScreenCaptureView.hidden = NO;
    
    // Hide web view
    self.webViewFullScreen.hidden = YES;
    
    // Display ECT View
    self.mobileECTView.hidden = NO;
    
    // Show ECT Helper
    [self openECTHelper];
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController lockInterfaceToOrientation:UIInterfaceOrientationPortrait];
    
    // Show microphone button
    self.ectMicrophoneButton.hidden = NO;
    self.ectSendFeedbackButton.hidden= YES;
    
    // Reset feedback textview
    self.ectTextView.textColor = [UIColor grayColor];
    self.ectTextView.text = @"Type your message here...";
    
    [self showTextAreaOrPlayButton];
    
}

-(void)closeECTView{
    self.ectStatusView.hidden = YES;
    
    // Close keyboard
    [self.view endEditing:YES];
    
    // Show navigation toolbar
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    // Hide ECT View
    self.mobileECTView.hidden = YES;
    
    // Reset ECT contents
    [self.ectScreenCaptureView clearCanvas];
    self.ectTextView.text = @"";
    self.ectToolbarBottomConstraint.constant = 0;
    self.ectToolbarHeightConstraint.constant = ECT_TOOLBAR_HEIGHT;
    [self.view layoutIfNeeded];
    
    // Show web view
    self.webViewFullScreen.hidden = NO;
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController unlockInterfaceOrientation];
    
    // Clear recorder
    [self deleteRecording];

    self.ectSubmissionFailed = NO;
}


-(void)showTextAreaOrPlayButton{
    self.ectTextView.hidden = self.hasAudioComments;
    self.ectMicrophoneButton.hidden = self.hasAudioComments;
    self.ectPlayAudioButton.hidden = !self.hasAudioComments;
    self.ectSendFeedbackButton.hidden = !self.hasAudioComments;
}

# pragma mark - ECT Feedback Submission
-(NSString*)getECTJSValue:(NSString*)expression{
    NSString *result = [self.applicationBrowser.webView stringByEvaluatingJavaScriptFromString:expression];

    return result;
}

-(NSMutableDictionary*) getECTFeedbackDictonary{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    // Message
    NSString* messageString = @"";
    
    if(![self hasAudioComments])
        messageString = self.ectTextView.text;
    
    [result setObject:messageString forKey:kECTFeedbackMessage];
    
    // EnvironmentUID - Available in outsystems.api.requestInfo.getEnvironmentKey()
    NSString* environmentUID = [self getECTJSValue:kECTJSEnvironmentUID];
    [result setObject:environmentUID forKey:kECTFeedbackEnvironmentUID];
    
    // EspaceUID - Available in outsystems.api.requestInfo.getEspaceKey()
    NSString* espaceUID = [self getECTJSValue:kECTJSEspaceUID];
    [result setObject:espaceUID forKey:kECTFeedbackEspaceUID];
    
    // ApplicationUID - Available in outsystems.api.requestInfo.getApplicationKey()
    NSString* applicationUID = [self getECTJSValue:kECTJSApplicationUID];
    [result setObject:applicationUID forKey:kECTFeedbackApplicationUID];
    
    // ScreenUID - Available in outsystems.api.requestInfo.getWebScreenKey()
    NSString* screenUID = [self getECTJSValue:kECTJSScreenUID];
    [result setObject:screenUID forKey:kECTFeedbackScreenUID];
    
    // ScreenName - Available in outsystems.api.requestInfo.getWebScreenName()
    NSString* screenName = [self getECTJSValue:kECTJSScreenName];
    [result setObject:screenName forKey:kECTFeedbackScreenName];
    
    // UserId - Available in ECT_JavasScript.userId
    NSString* userId = [self getECTJSValue:kECTJSUserId];
    [result setObject:userId forKey:kECTFeedbackUserId];
    
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    // ViewportWidth
    NSNumber *screenWidth = [NSNumber numberWithDouble:screenBounds.size.width];
    NSString* viewportWidth = [screenWidth stringValue];
    [result setObject:viewportWidth forKey:kECTFeedbackViewportWidth];
    
    // ViewportHeight
    NSNumber *screenHeight = [NSNumber numberWithDouble:screenBounds.size.height];
    NSString* viewportHeight = [screenHeight stringValue];
            [result setObject:viewportHeight forKey:kECTFeedbackViewportHeight];
    
    // UserAgentHeader - Use this JS navigator.userAgent
    NSString* userAgentHeader = [self getECTJSValue:kECTJSUserAgentHeader];
    [result setObject:userAgentHeader forKey:kECTFeedbackUserAgentHeader];
    
    // RequestURL
    NSString* requestURL = self.applicationBrowser.webView.request.URL.absoluteString;
    [result setObject:requestURL forKey:kECTFeedbackRequestURL];
    

    // FeedbackSoundMessageBase64
    NSString *audioString = @"";
    
    if([self hasAudioComments]){
        
        NSData *audioData = [NSData dataWithContentsOfURL:self.recorder.url];
        
        if(audioData){
            if ([audioData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
                audioString = [audioData base64EncodedStringWithOptions:kNilOptions];  // iOS 7+
            } else {
                audioString = [audioData base64Encoding];                              // pre iOS7
            }
        }
    }
    
    NSString* feedbackSoundMessageBase64 = audioString;
    [result setObject:feedbackSoundMessageBase64 forKey:kECTFeedbackSoundMessageBase64];
    
    // FeedbackSoundMessageMimeType
    NSString* feedbackSoundMessageMimeType = kECTAudioMimeType;
    [result setObject:feedbackSoundMessageMimeType forKey:kECTFeedbackSoundMessageMimeType];
    
    //  FeedbackScreenshotBase64
    UIImage *ectImage = [self.ectScreenCaptureView getCanvasImage];
    NSString *imageString = @"";
    
    if(ectImage){
        NSData * imageData = UIImageJPEGRepresentation(ectImage, 0.5);
        
        if(imageData){
            if ([imageData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
                imageString = [imageData base64EncodedStringWithOptions:kNilOptions];  // iOS 7+
            } else {
                imageString = [imageData base64Encoding];                              // pre iOS7
            }
        }
    }
    
    NSString* feedbackScreenshotBase64 = imageString;
    [result setObject:feedbackScreenshotBase64 forKey:kECTFeedbackScreenshotBase64];

    // FeedbackScreenshotMimeType
    NSString* feedbackScreenshotMimeType = kECTImageMimeType;
    [result setObject:feedbackScreenshotMimeType forKey:kECTFeedbackScreenshotMimeType];

    return result;
}

-(NSString*) getECTFeedbackPostURL{
    
    NSMutableDictionary *ectFeedback = [self getECTFeedbackDictonary];
    NSString* result = @"";
 
    NSArray*keys=[ectFeedback allKeys];
    
    for(int i=0; i < [keys count]; i++){
        NSString *key = keys[i];
        NSString *value = [ectFeedback valueForKey:key];
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@=%@",key,value]];
        if(i+1 < [keys count]){
            result = [result stringByAppendingString:@"&"];
        }
    }
    
    return result;
}

-(void)sendECTFeedback{
    
    self.ectSubmissionFailed = NO;
    
    int timeoutInSeconds = 30;
    
    MobileECT *mobileECT = [self getOrCreateMobileECTInfo];
    
    NSString* ectURL = ((ECTApi*)[self.ectSupportedApiVersions firstObject]).url;
    
    NSURL *serviceURL = [NSURL URLWithString:[mobileECT getServiceForInfrastructure:self.infrastructure andURL:ectURL]];
    
    NSString *post = [self getECTFeedbackPostURL];
    
    post = [post stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *serviceRequest = [NSMutableURLRequest requestWithURL:serviceURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeoutInSeconds];
    
    [serviceRequest setHTTPMethod:@"POST"];
    [serviceRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [serviceRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [serviceRequest setHTTPBody:postData];
    
    NSLog(@"Logging in: %@", serviceURL);
    
    [NSURLConnection connectionWithRequest:serviceRequest delegate:self];
    
}

-(void)showECTFailMessage{
    self.ectSubmissionFailed = YES;
    self.ectStatusView.hidden = NO;
    self.ectActivityIndicator.hidden = YES;
    self.ectRetryButton.hidden = NO;
    self.ectCancelRetryButton.hidden = NO;
    self.ectStatusMessage.text = kECTStatusFailed;
    
    // Check if the device is not an iPad
    if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad )
    {
        self.ectStatusMessage.adjustsFontSizeToFitWidth=YES;
        self.ectStatusMessage.minimumScaleFactor=0.5;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    NSInteger errorCode = httpResponse.statusCode;
    NSString *fileMIMEType = [[httpResponse MIMEType] lowercaseString];
    NSLog(@"response is %ld, %@", (long)errorCode, fileMIMEType);
    if(errorCode != 200)
       [self showECTFailMessage];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    [self showECTFailMessage];

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connection finished");

    if(!self.ectSubmissionFailed){
        [self closeECTView];
    }
}



#pragma mark - Core Data for ECT

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}



- (MobileECT*) getOrCreateMobileECTInfo {
    MobileECT *mobileECT;
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MobileECT"];
    NSMutableArray *results = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    if([results count] > 0) {
        mobileECT = [results objectAtIndex:0];
        
    } else {
        mobileECT = [NSEntityDescription insertNewObjectForEntityForName:@"MobileECT" inManagedObjectContext:[self managedObjectContext]];
        mobileECT.isFirstLoad = YES;
    }
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
    return mobileECT;
}

# pragma mark - ECT Helper

-(void) openECTHelper{
    
    // Show helper if it's the first time
    MobileECT* mobileECTInfo = [self getOrCreateMobileECTInfo];

    if(mobileECTInfo.isFirstLoad){

        // Get iOS Version
        float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        
        // Get ECT Helper Image
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self calculateECTHelperImage:currentOrientation];
        
        // Create blurred view effect
        if(iOSVersion < 8){
            self.ectHelperView.alpha = 1;
            
            CAGradientLayer *gradient = [CAGradientLayer layer];
            gradient.frame = self.ectHelperView.bounds;
            gradient.colors = [NSArray arrayWithObjects:
                               (id)[[UIColor colorWithRed:0.537 green:0.549 blue:0.565 alpha:1] /*#898c90*/ CGColor],
                               (id)[[UIColor colorWithRed:0.843 green:0.843 blue:0.843 alpha:1] /*#d7d7d7*/ CGColor],
                               (id)[[UIColor colorWithRed:0.969 green:0.969 blue:0.969 alpha:1] /*#f7f7f7*/ CGColor], nil];
            [self.ectHelperView.layer insertSublayer:gradient atIndex:0];
            
        }
        else{
            UIVisualEffect *blurEffect;
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            UIVisualEffectView *visualEffectView;
            
            // Check if VisualEffectView already exists
            NSArray* subViews =[self.ectHelperView subviews];
            for(int i=0; i < [subViews count]; i++){
                if([subViews[i] isKindOfClass: [UIVisualEffectView class]]){
                    visualEffectView = subViews[i];
                    break;
                }
            }
            
            if(!visualEffectView)
                visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            
            visualEffectView.frame = self.ectHelperView.bounds;
            
            [self.ectHelperView addSubview:visualEffectView];
            [self.ectHelperView sendSubviewToBack:visualEffectView];
            [self.view layoutIfNeeded];
        }
        
        [self.mobileECTView sendSubviewToBack:self.ectScreenCaptureView];
        self.ectHelperView.hidden = NO;
        self.ectHelperImageView.hidden = NO;
    }
    else{
        self.ectHelperImageView.hidden = YES;
        self.ectHelperView.hidden = YES;
    }

}

- (void)onECTHelperTaped:(UIGestureRecognizer *)gestureRecognizer {
    self.ectHelperView.hidden = YES;
    MobileECT *mobileECTInfo = [self getOrCreateMobileECTInfo];
    mobileECTInfo.isFirstLoad = NO;
}

-(void) calculateECTHelperImage:(UIInterfaceOrientation)toInterfaceOrientation{
    
    bool portraitOrientation = toInterfaceOrientation == UIInterfaceOrientationPortrait ||
                                 toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
    
    bool iPhoneDevice = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    if(iPhoneDevice){
        if(screenBounds.size.height < IPHONE5_HEIGHT){
            // iPhone 4, 4s
            if(portraitOrientation)
                self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_4-4S_portrait.png"];
            else
                self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_4-4S_landscape.png"];
        }
        else{
            if(screenBounds.size.height == IPHONE5_HEIGHT){
                    // iPhone 5
                if(portraitOrientation)
                    self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_5_portrait.png"];
                else
                    self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_5_landscape.png"];
            }
            else {
                if(screenBounds.size.height == IPHONE6_HEIGHT){
                    // iPhone 6
                    if(portraitOrientation)
                        self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_6_portrait.png"];
                    else
                        self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_6_landscape.png"];
                }
                else{
                    // iPhone 6+
                    if(portraitOrientation)
                        self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_6+_portrait.png"];
                    else
                        self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPhone_6+_landscape.png"];
                }
            }
        }
        
        
    }
    else{
        
        if(portraitOrientation)
            self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPad_portrait"];
        else
            self.ectHelperImageView.image = [UIImage imageNamed:@"ECTSketch_iPad_landscape"];
        
    }
    
    
}



@end
