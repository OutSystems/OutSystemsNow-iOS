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

@property (weak, nonatomic) IBOutlet UIBarButtonItem* openMobileECTButton;
@property (strong, nonatomic) NSMutableArray *originalToolbarItems;

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
    
    [self.mobileECTView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.mobileECTView setHidden:YES];
    
    // Mobile ECT Configuration
    self.mobileECTController = [[OSMobileECTController alloc] initWithSuperView:self.mobileECTView
                                                                     andWebView:self.applicationBrowser.webView
                                                                    forHostname:self.infrastructure.hostname ];
    
    [self.mobileECTController addOnExitEvent:self withSelector:@selector(onExitECT)];
    
    [self.mobileECTController prepareForViewDidLoad];

    
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbar.hidden = NO;
    self.navigationController.navigationBar.hidden = YES;
    
    self.applicationBrowser.webView.scalesPageToFit = YES;
    [self.applicationBrowser setStartPage:_application.path];
    
    self.lastContentOffset = 0;
    
    self.loadingView.hidden = YES;
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController unlockInterfaceOrientation];

    [self.mobileECTController prepareForViewWillAppear];
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
    BOOL isECTAvailable = [self.mobileECTController isECTFeatureAvailable];
    
    if(isECTAvailable)
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


# pragma mark - Mobile ECT

- (IBAction)onOpenECT:(id)sender {

    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController lockInterfaceToOrientation:UIInterfaceOrientationPortrait];

    [self.navigationController setToolbarHidden:YES animated:YES];
    
    MobileECT *mobileECTCoreData = [self getOrCreateMobileECTInfo];
    
    BOOL skipECTHelper = (mobileECTCoreData && !mobileECTCoreData.isFirstLoad);
    
    [self.mobileECTController skipHelper:skipECTHelper];

    [self.mobileECTView setHidden:NO];
    [self.mobileECTController openECTView];
    
}

-(void)onExitECT{

    MobileECT *mobileECTCoreData = [self getOrCreateMobileECTInfo];
    mobileECTCoreData.isFirstLoad = NO;
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController unlockInterfaceOrientation];
    
    [self.mobileECTView setHidden:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
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


@end
