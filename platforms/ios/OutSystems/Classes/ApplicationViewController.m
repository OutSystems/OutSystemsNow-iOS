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
#import "OSNavigationController.h"
#import "OfflineSupportController.h"
#import "OSProgressBar.h"

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

// Offline Support
@property (weak, nonatomic) IBOutlet UIView *networkErrorView;
@property (weak, nonatomic) IBOutlet UIImageView *errorImage;
@property (weak, nonatomic) IBOutlet UITextField *errorTitleMessage;
@property (weak, nonatomic) IBOutlet UITextField *errorBodyMessage;
@property (weak, nonatomic) IBOutlet UIButton *errorRetryButton;
@property (weak, nonatomic) IBOutlet UIButton *errorBackToAppsButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *errorActivityIndicator;
@property (strong, nonatomic) NSString *failedURL;

// Mobile Improvements
@property BOOL applicationHasPreloader;
@property (strong, nonatomic) OSProgressBar *progressBar;


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
    _applicationBrowser = [CDVViewController new];
  
    _applicationBrowser.startPage = @"";
    _applicationBrowser.wwwFolderName = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewDidStartLoad:)
                                                 name:@"CDVPluginResetNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewDidFinishLoad:)
                                                 name:@"CDVPageDidLoadNotification"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webViewdidFailLoadWithError:)
                                                 name:@"CDVPageDidFailLoadNotification"
                                               object:nil];
    
    self.firstLoad = YES;
    
    self.applicationBrowser.view.frame = self.webViewFullScreen.frame;
    
    [self addChildViewController:self.applicationBrowser];
    [self.webViewFullScreen addSubview:self.applicationBrowser.view];
    
    // remove bounce effect
    self.applicationBrowser.webView.scrollView.bounces = NO;
    
    
    // Hide Nav App List button
    if(self.isSingleApplication){
        NSMutableArray *toolbarButtons = [self.toolbarItems mutableCopy];
        [toolbarButtons removeObject:self.navAppList];
        [self setToolbarItems:toolbarButtons animated:YES];
    }

    self.originalToolbarItems = [self.toolbarItems mutableCopy];
    
    // Hide Mobile ECT button
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

    
    // WebView Request
    
    BOOL networkAvailable = [OfflineSupportController isNetworkAvailable:_infrastructure];

    NSURLRequest *request = nil;
    
    if ([OfflineSupportController isNewSession]){
        [_applicationBrowser.webView stringByEvaluatingJavaScriptFromString:@"localStorage.clear();"];
    }
    
    if (networkAvailable || [OfflineSupportController isNewSession]){
        request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/", _application.path]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    }
    else{
        request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/", _application.path]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
    }
    
    [_applicationBrowser.webView loadRequest:request];
    
    // Check the cache.
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    NSLog(cachedResponse ? @"Cached response found!" : @"No cached response found.");
    
    
    // Offline Support
    self.errorRetryButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:self.errorRetryButton.titleLabel.font.pointSize];

    [self.errorRetryButton.layer setBorderWidth:0.5];
    [self.errorRetryButton.layer setBorderColor:[UIColor whiteColor].CGColor];

    self.errorRetryButton.layer.cornerRadius = 5;
    
    [self.errorActivityIndicator stopAnimating];
    
    [self showNetworkErrorView:NO];
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController unlockInterfaceOrientation];
    _failedURL = nil;
    
    // Mobile Improvements
    _applicationHasPreloader = NO;
    
    if(_application)
        _applicationHasPreloader = _application.preloader;
    
    // Progress Bar
    _progressBar = [[OSProgressBar alloc] initForView:_loadingProgressView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbar.hidden = NO;
    self.navigationController.navigationBar.hidden = YES;
    
    self.applicationBrowser.webView.scalesPageToFit = YES;
    
    self.lastContentOffset = 0;
    
    self.loadingView.hidden = YES;
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController unlockInterfaceOrientation];

    if(!self.mobileECTController){
        self.mobileECTController = [[OSMobileECTController alloc] initWithSuperView:self.mobileECTView
                                                                         andWebView:self.applicationBrowser.webView
                                                                        forHostname:self.infrastructure.hostname ];
        
        [self.mobileECTController addOnExitEvent:self withSelector:@selector(onExitECT)];
        
        [self.mobileECTController prepareForViewDidLoad];
        
        [self.mobileECTController isECTFeatureAvailable];
        
    }
        
    
    [self.mobileECTController prepareForViewWillAppear];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    if(self.viewFinishedLoad == YES && self.loadingView.hidden==NO){
        self.loadingView.hidden= YES;
    }
    [super viewDidAppear:animated];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    for (CALayer* layer in [self.view.layer sublayers])
    {
        [layer removeAllAnimations];
    }
    
    [self.mobileECTController prepareForUnload];
    self.mobileECTController = nil;
    
    self.webViewStaticImageLoading = nil;
    self.failedURL = nil;
    
    [super viewWillDisappear:animated];
}

-(void) viewDidDisappear:(BOOL)animated{

    [super viewDidDisappear:animated];
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
    
    //[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadingTimer) userInfo:nil repeats:NO];

    if(!_applicationHasPreloader){
        [_progressBar startProgress:YES];
    }
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

    BOOL networkAvailable = [OfflineSupportController isNetworkAvailable:_infrastructure];
    
    if(isECTAvailable && networkAvailable)
        [self setToolbarItems:self.originalToolbarItems animated:YES];
    
    [self showNetworkErrorView:NO];
    
    
    if(_applicationHasPreloader){
        
        UIWebView *webview = [notification object];
       
        NSString *currentURL = webview.request.URL.absoluteString;
        NSLog(@"CurrentURL: %@",currentURL);

        NSRange preloader = [currentURL rangeOfString:@"preloader.html"];
        _applicationHasPreloader = preloader.location != NSNotFound;
        
    }else{
        [_progressBar stopProgress:YES];
    }
    
}


-(void)webViewdidFailLoadWithError:(NSNotification *) notification {
    
    NSDictionary *userInfo = [notification userInfo];
    NSError *error = [userInfo valueForKey:@"error"];
    
    
    switch([error code]){
        case NSURLErrorTimedOut:
        case NSURLErrorUnsupportedURL:
        case NSURLErrorCannotFindHost:
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorDNSLookupFailed:
        case NSURLErrorResourceUnavailable:
        case NSURLErrorNotConnectedToInternet:{

            _failedURL = [error.userInfo objectForKey:@"NSErrorFailingURLStringKey"];
            NSLog(@"webViewdidFailLoadWithError: %@", _failedURL);
            [_progressBar stopProgress:YES];
            [self showNetworkErrorView:YES];

            break;
        }
        default:
            // do nothing
            [_progressBar cancelProgress:YES];
            break;
    }

}

-(void)transitionPrepareAnimation:(OSAnimateTransition) animateTransition {
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController lockCurrentOrientation:YES];
    
    if(!self.firstLoad) {
        UIImage *viewImage = [self captureCurrentWebPage];
        self.webViewImageLoading.image = viewImage;
        viewImage = nil;
	
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
        self.webViewStaticImageLoading = nil;
		
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
                             self.webViewImageLoading.image = nil;
						 }];
		
	}
    
	// reset to default transition
	self.selectedTransition = OSAnimateTransitionDefault;
	
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController lockCurrentOrientation:NO];
}


-(UIImage*)captureCurrentWebPage{
    
    // Capture the current page in an image and render it on the view
    // that will sit over the webview
    UIGraphicsBeginImageContextWithOptions(self.applicationBrowser.view.bounds.size,
                                           self.applicationBrowser.view.opaque,
                                           0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if(context){
        @try {
            [self.applicationBrowser.view.layer renderInContext:context];
        }
        @catch (NSException *exception) {
            NSLog(@"Failed to render webview layer");
            CGContextSetRGBFillColor(context,1.0, 1.0, 1.0, 1.0);
            CGContextFillRect(context,self.applicationBrowser.view.bounds);
            CGContextSaveGState(context);
        }
    }
    else{
        NSLog(@"UIGraphics Context not available");
    }

    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}


# pragma mark - Mobile ECT

- (IBAction)onOpenECT:(id)sender {

    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController lockCurrentOrientation:YES];
    
    MobileECT *mobileECTCoreData = [self getOrCreateMobileECTInfo];
    
    BOOL skipECTHelper = (mobileECTCoreData && !mobileECTCoreData.isFirstLoad);
    
    [self.mobileECTController skipHelper:skipECTHelper];


    [self.mobileECTController openECTView];
 
    [self.navigationController setToolbarHidden:YES animated:YES];
    [self.mobileECTView setHidden:NO];   
}

-(void)onExitECT{

    MobileECT *mobileECTCoreData = [self getOrCreateMobileECTInfo];
    mobileECTCoreData.isFirstLoad = NO;
    
    OSNavigationController *navController = (OSNavigationController*)self.navigationController;
    [navController lockCurrentOrientation:NO];
    
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


# pragma mark - Offline Support
-(void)showNetworkErrorView:(BOOL)show{

    [_networkErrorView setHidden:!show];
    
    if(show){
        [self errorRetryActionFailed];
    }
    
}

-(void)errorRetryActionFailed{
    // shake on error
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 2.0f ;
    anim.duration = 0.07f ;
    
    [self.view.layer addAnimation:anim forKey:nil ] ;
    
    [_errorActivityIndicator stopAnimating];
    [_errorRetryButton setHidden:NO];
}

- (IBAction)errorRetryAction:(id)sender {
    [_errorActivityIndicator startAnimating];
    [_errorRetryButton setHidden:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reloadWebView) userInfo:nil repeats:NO];
}

-(void)reloadWebView{
    
    [OfflineSupportController retryWebViewAction:_applicationBrowser.webView failedURL:_failedURL forApplication:_application andInfrastructure:_infrastructure];
}

- (IBAction)backToApplicationsAction:(id)sender {
    [self navAppList:sender];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:@"CDVPluginResetNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:@"CDVPageDidLoadNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:@"CDVPageDidFailLoadNotification"
                                               object:nil];
}

@end
