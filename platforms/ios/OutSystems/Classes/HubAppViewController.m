//
//  HubAppViewController.m
//  HubApp
//
//  Created by engineering on 01/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//
#import "HubAppViewController.h"
#import "LoginScreenController.h"
#import "Infrastructure.h"
#import "UIInsetTextField.h"
#import "ApplicationTileListController.h"
#import "OutSystemsAppDelegate.h"
#import "OSNavigationController.h"
#import "DemoInfrastructure.h"
#import "OfflineSupportController.h"

@interface HubAppViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *connectionActivityIndicator;

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *errorMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIButton *tryDemoButton;
@property (weak, nonatomic) IBOutlet UIButton *explainURLButton;
@property (weak, nonatomic) IBOutlet UIInsetTextField *environmentHostname;

@property (strong, nonatomic) NSMutableArray *environments;

@property (strong, nonatomic) Infrastructure *infrastructure;

@property (weak, nonatomic) IBOutlet UILabel *accessYourAppLabel;
@property (weak, nonatomic) IBOutlet UILabel *explainURLLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksLabel;
@property (weak, nonatomic) IBOutlet UIView *helpView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *helpURLHeightContraint;

@property (weak, nonatomic) NSData *loginResponseData;
@property NSArray* trustedHosts;
@property NSInteger connectionErrorCode;
@property BOOL tryAnotherStack;

@property (weak, nonatomic) NSString *defaultEnvironment;
@property (weak, nonatomic) NSString *defaultUsername;
@property (weak, nonatomic) NSString *defaultPassword;
@property BOOL defaultIsJavaEnvironment;
@property BOOL infrastructureReadonly;
@property BOOL loginReadonly;



@end

@implementation HubAppViewController

// The Managed app configuration dictionary pushed down from an MDM server are stored in this key.
static NSString * const kConfigurationKey = @"com.apple.configuration.managed";

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.toolbar.hidden = YES;
    
    
    UIStoryboard *storyboard = self.storyboard;
    LoginScreenController *targetViewControler = [storyboard instantiateViewControllerWithIdentifier:@"LoginScreen"];
    
    // Disable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
   
    // Get Infrastructure settings
    [self getInfrastructureSettings];
    
    targetViewControler.infrastructureReadonly = self.infrastructureReadonly;
    targetViewControler.loginReadonly = self.loginReadonly;
    

    // check if deep link is valid
    if([self.deepLinkController hasValidSettings]){
    
        // proceed according to the deep link operation
        [self.deepLinkController resolveOperation:self];
            
    }
    else{
        // check if we have the login and password for that infrastructure or we're using a default infrastructure
        if(([self.infrastructure.username length] > 0 && [self.infrastructure.password length] > 0) ||[_defaultEnvironment length] > 0) {
            
            // execute the login automatically if not done yet
            if( [OutSystemsAppDelegate hasAutoLoginPerformed] == NO) {
                UINavigationController *navControler = self.navigationController;
                    
                if(navControler) {
                    targetViewControler.infrastructure = self.infrastructure;
                    targetViewControler.deepLinkController = self.deepLinkController;
                    [navControler pushViewController:targetViewControler animated:NO];
                }
            }
        }
    }
    
    
    bool iPhoneDevice = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    
    if(iPhoneDevice){
        OSNavigationController *navController = (OSNavigationController*)self.navigationController;
        [navController lockInterfaceToOrientation:UIInterfaceOrientationPortrait];
    }
    
}

- (void)getInfrastructureSettings{
    self.infrastructureReadonly = NO;
    self.loginReadonly = NO;
    
    
    // MDM specific settings
    if(_defaultEnvironment && [_defaultEnvironment length] > 0) {
        
        self.infrastructureReadonly = YES;
        
        self.infrastructure = [self getOrCreateInfrastructure:_defaultEnvironment];
        
        self.infrastructure.name = _defaultEnvironment;
        self.infrastructure.username = _defaultUsername;
        self.infrastructure.password = _defaultPassword;
        self.infrastructure.isJavaServer = _defaultIsJavaEnvironment;
        self.infrastructure.hostname = _defaultEnvironment;
        
        if([self.infrastructure.username length] > 0 && [self.infrastructure.password length] > 0) {
            self.loginReadonly = YES;
        }
        
    } else {
        
        if(self.deepLinkController && [self.deepLinkController hasValidSettings]){
            // Get the infrastructure info from the deep link settings
            DeepLink* deepLinkSettings = [self.deepLinkController getSettings];
            
            NSString *deepLinkEnvironment =[deepLinkSettings environment];
            
            self.infrastructure = [self getOrCreateInfrastructure:deepLinkEnvironment];
            
            NSLog(@"DeepLink - Hostname: %@",deepLinkEnvironment);

            NSLog(@"autologin? %d",[OutSystemsAppDelegate hasAutoLoginPerformed]);

            
        }
        else{
            // Fetch the environments from persistent data store
            self.environments = [self fetchEnvironments];
            
            if(self.environments.count > 0) {
                
                // Get this first env. from the list (the last env. accessed)
                self.infrastructure = [self.environments objectAtIndex:0];
                
                self.environmentHostname.text = self.infrastructure.hostname;
            }
            
        }
    }
    
    if(self.infrastructureReadonly){
        self.environmentHostname.enabled = NO;
        self.environmentHostname.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    }
    
    self.environmentHostname.text = self.infrastructure.hostname;
    
}

- (NSMutableArray*)fetchEnvironments{
    
    // Fetch the environments from persistent data store
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Infrastructure"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO];;
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSMutableArray *environmentsArray = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    return environmentsArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.accessYourAppLabel.font = [UIFont fontWithName:@"OpenSans" size:self.accessYourAppLabel.font.pointSize];
    self.explainURLLabel.font = [UIFont fontWithName:@"OpenSans" size:self.explainURLLabel.font.pointSize];
    self.howItWorksLabel.font = [UIFont fontWithName:@"OpenSans" size:self.howItWorksLabel.font.pointSize];
    
    self.environmentHostname.font = [UIFont fontWithName:@"OpenSans" size:self.environmentHostname.font.pointSize];
    self.goButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:self.goButton.titleLabel.font.pointSize];
    self.tryDemoButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:self.tryDemoButton.titleLabel.font.pointSize];
    
    [self.goButton.layer setBorderWidth:0.5];
    [self.goButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [self.tryDemoButton.layer setBorderWidth:0.5];
    [self.tryDemoButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"OShub_bg-red.jpg"]]];
    
    self.goButton.layer.cornerRadius = 5;
    self.tryDemoButton.layer.cornerRadius = 3;
    self.environmentHostname.layer.cornerRadius = 5;
    
    // hide the url help text at start
    [self.helpView setFrame:CGRectMake(self.helpView.frame.origin.x, self.helpView.frame.origin.y, self.helpView.frame.size.width, 0)];
    self.helpURLHeightContraint.constant = 0;
    
    self.trustedHosts = [[NSArray alloc] initWithObjects:@"outsystems.com", @"outsystems.net", @"outsystemscloud.com", nil];
    
    UIColor *color = [UIColor whiteColor];
    NSArray *keys = [[NSArray alloc] initWithObjects:(id)kCTForegroundColorAttributeName,(id)kCTUnderlineStyleAttributeName
                     , nil];
    NSArray *objects = [[NSArray alloc] initWithObjects:color, [NSNumber numberWithInt:kCTUnderlineStyleSingle], nil];
    NSDictionary *linkAttributes = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    
    self.errorMessageLabel.linkAttributes = linkAttributes;
    self.errorMessageLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    
    // Add Notification Center observer to be alerted of any change to NSUserDefaults.
    // Managed app configuration changes pushed down from an MDM server appear in NSUSerDefaults.
    /*[[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self readDefaultsValues];
                                                  }];*/
    
    // Call readDefaultsValues to make sure default values are read at least once.
    [self readDefaultsValues];
    
    // hide the keyboard when the user clicks outside the hostname textbox
    // set the tap gesture recognizer
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    
    [self.view addGestureRecognizer:singleTap];
    
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender{
    // hide the keyboard when the user clicks outside the hostname textbox
    [self.environmentHostname resignFirstResponder];
    
}

- (void)readDefaultsValues {
    
    NSLog(@"-> readDefaultsValues");
    
    NSDictionary *serverConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kConfigurationKey];
    
    if(serverConfig && serverConfig.count > 0) {
        NSLog(@"Found user settings for [%@]", kConfigurationKey);
        
        NSString *environment_address = serverConfig[@"Address"];
        NSString *environment_username = serverConfig[@"Username"];
        NSString *environment_password = serverConfig[@"Password"];
        BOOL environment_IsJavaServer = NO;
        
        if([serverConfig valueForKey:@"IsJavaServer"]) {
            environment_IsJavaServer =[[serverConfig valueForKey:@"IsJavaServer"] boolValue];
            if(environment_IsJavaServer) {
                NSLog(@"IsJavaServer [YES]");
            } else {
                NSLog(@"IsJavaServer [NO]");
            }
            _defaultIsJavaEnvironment = environment_IsJavaServer;
        }
        
        // Data coming from MDM server should be validated before use.
        // If validation fails, be sure to set a sensible default value as a fallback, even if it is nil.
        if (environment_address && [environment_address isKindOfClass:[NSString class]]) {
            _defaultEnvironment = environment_address;
            NSLog(@"Default address [%@]", environment_address);
        }
        if (environment_username && [environment_address isKindOfClass:[NSString class]]) {
            _defaultUsername = environment_username;
            NSLog(@"Default username [%@]", environment_username);
        }
        if (environment_password && [environment_address isKindOfClass:[NSString class]]) {
            _defaultPassword = environment_password;
            NSLog(@"Default password [*****]");
        }

    } else {
        NSLog(@"No server config settings found for [%@]", kConfigurationKey);
    }
    
    NSLog(@"<- readDefaultsValues");
}


- (IBAction)onHelpTouch:(id)sender {
    UIImage * btnNextImage;
    
    if(self.helpView.frame.size.height > 0) {
        btnNextImage = [UIImage imageNamed:@"icon-white-help.png"];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.helpView setFrame:CGRectMake(self.helpView.frame.origin.x, self.helpView.frame.origin.y, self.helpView.frame.size.width, 0)];
            self.helpURLHeightContraint.constant = 0;
            [self.view layoutIfNeeded];
            
        }];
    }
    else {
        btnNextImage = [UIImage imageNamed:@"icon-white-close.png"];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.helpView setFrame:CGRectMake(self.helpView.frame.origin.x, self.helpView.frame.origin.y, self.helpView.frame.size.width, 70)];
            self.helpURLHeightContraint.constant = 70;
            [self.view layoutIfNeeded];
            
        }];
    }
    
    [self.explainURLButton setImage:btnNextImage forState:UIControlStateNormal];
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

- (IBAction)didGoOnExitHostnameText:(id)sender {
    [self OnGoClick:_goButton];
}

-(NSString*)checkEnvironmentURL:(NSString*)url{

    NSArray* words = [url componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* noSpaceString = [words componentsJoinedByString:@""];
    
    NSURL *hubUrl = [NSURL URLWithString:noSpaceString];
   
    if (hubUrl && hubUrl.host) {
        return hubUrl.host;
    }
    else{
        NSString *http = @"http://";
        NSString *https = @"https://";
        
        if ([noSpaceString hasPrefix:http]) {
            return [noSpaceString substringFromIndex:[http length]];
        }
        else{
            if ([noSpaceString hasPrefix:https]) {
                return [noSpaceString substringFromIndex:[https length]];
            }
            else{
                NSRange slash = [noSpaceString rangeOfString:@"/"];
                if(slash.location != NSNotFound){
                    return  [noSpaceString substringToIndex:slash.location];
                }
            }
        }
        
    }
    return noSpaceString;
}

- (IBAction)OnGoClick:(UIButton *)sender {
    // Dismiss keyboard
    [self.view endEditing:YES];
    
    [self.connectionActivityIndicator startAnimating];
    [self.errorMessageLabel setHidden:YES];
    [self.goButton setHidden:YES];
    [self.tryDemoButton setEnabled:NO];
    
    //reset the flag
    self.tryAnotherStack = NO;
    
    
    if(self.environmentHostname.text.length > 0) {
        NSString *hostname = self.environmentHostname.text;
        
        NSString *hubURL = [self checkEnvironmentURL:hostname];
        
        if(hostname != hubURL){
            hostname = hubURL;
            [self.environmentHostname setText: hostname];
        }
        
        self.infrastructure = [self getOrCreateInfrastructure:hostname];
        
        [self connectToInfrastructure:self.infrastructure];
        
    } else {
        self.errorMessageLabel.text = @"Please enter a valid OutSystems network address";
        
        // shake on error
        CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
        anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
        anim.autoreverses = YES ;
        anim.repeatCount = 2.0f ;
        anim.duration = 0.07f ;
        
        [self.view.layer addAnimation:anim forKey:nil ] ;
        
        [_connectionActivityIndicator stopAnimating];
        [_errorMessageLabel setHidden:NO];
        [_goButton setHidden:NO];
        [self.tryDemoButton setEnabled:YES];
    }
}

- (Infrastructure*) getOrCreateInfrastructure: (NSString*) hostname {
    Infrastructure *infrastructure;
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Infrastructure"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO];;
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"hostname == %@", hostname]];
    NSMutableArray *environments = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    if([environments count] > 0) {
        infrastructure = [environments objectAtIndex:0];
        infrastructure.lastUsed = [NSDate date];

    } else {
        infrastructure = [NSEntityDescription insertNewObjectForEntityForName:@"Infrastructure" inManagedObjectContext:[self managedObjectContext]];
        infrastructure.hostname = hostname;
        infrastructure.name = self.infrastructure.name;
        infrastructure.lastUsed = [NSDate date];
        infrastructure.isJavaServer = NO; // set default to NO
    }
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
    return infrastructure;
}

- (void) connectToInfrastructure:(Infrastructure*) infrastructure {
    
    self.connectionErrorCode = 0; // clear previous error code
    [_errorMessageLabel setHidden:YES];
    
    NSURL *myUrl = [NSURL URLWithString:[self.infrastructure getHostnameForService:@"infrastructure"]];
    
    _loginResponseData = nil;
    
    NSURLRequest *myRequest = [NSURLRequest requestWithURL:myUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5];
    [NSURLConnection connectionWithRequest:myRequest delegate:self];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        for (NSString *trustedHost in self.trustedHosts) {
            
            // currently trusting all certificates for beta release, remove true condition to validate untrusted certificates with list for trusted servers
            if(true || [challenge.protectionSpace.host rangeOfString:trustedHost options:NSBackwardsSearch].location == (challenge.protectionSpace.host.length - trustedHost.length)) {
                [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
                break;
            }
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    self.connectionErrorCode = httpResponse.statusCode;
    NSString *fileMIMEType = [[httpResponse MIMEType] lowercaseString];
    NSLog(@"response is %ld, %@", (long)self.connectionErrorCode, fileMIMEType);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    _loginResponseData = data;
    NSLog(@"received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    self.errorMessageLabel.text = error.localizedDescription;
    
    [_connectionActivityIndicator stopAnimating];
    [_errorMessageLabel setHidden:NO];
    [_goButton setHidden:NO];
    [self.tryDemoButton setEnabled:YES];
    
    // shake on error
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 2.0f ;
    anim.duration = 0.07f ;
    
    [self.view.layer addAnimation:anim forKey:nil ] ;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSLog(@"connection finished");
    
    NSError *e = nil;
    NSDictionary *response = nil;
    BOOL success = NO;
    
    if(self.loginResponseData != nil) {
        response = [NSJSONSerialization JSONObjectWithData:_loginResponseData options:NSJSONReadingMutableContainers error:&e];
        
        if([[response objectForKey:@"Name"] isKindOfClass:[NSString class]]) {
            success = [(NSString*)[response objectForKey:@"Name"] length] > 0;
        }
    }
    
    if(success) {
        self.infrastructure.name = (NSString*)[response objectForKey:@"Name"];
        
        if(self.tryAnotherStack) {
            self.tryAnotherStack = NO; // reset flag
        }
        
        // update the infrastructure
        NSError *error = nil;
        // Save the object to persistent store
        if (![[self managedObjectContext] save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
        // refresh button states and stop spinning animation
        [_connectionActivityIndicator stopAnimating];
        [_goButton setHidden:NO];
        [self.tryDemoButton setEnabled:YES];
        
        // check OutSystemsNowService compatibility
        NSString *moduleVersion;
        if([[response objectForKey:@"version"] isKindOfClass:[NSString class]]) {
            moduleVersion = [response objectForKey:@"version"];
        }
        
        if(moduleVersion == nil || [moduleVersion rangeOfString:OutSystemsNowRequiredVersion].location != 0) {
            self.errorMessageLabel.text = @"Incompatible module version in your installation, please contact your system administrator to update the OutSystems Now modules";
            [_errorMessageLabel setHidden:NO];
        } else {
            [_errorMessageLabel setHidden:YES];
            [self performSegueWithIdentifier:@"GoToLoginSegue" sender:self];
        }
        
    } else {
        if(self.connectionErrorCode == 404 && self.tryAnotherStack == NO) {
            
            // failed to contact the server, look for java version or the OutSystems App service is not installed
            self.tryAnotherStack = YES;
            self.infrastructure.isJavaServer = !self.infrastructure.isJavaServer;
            [self connectToInfrastructure:self.infrastructure];
            
            return; // retry the new server type (.net/java) and don't give an error yet
            
        } else if(self.tryAnotherStack) {
            // no service found!
            self.errorMessageLabel.text = @"The required OutSystems Now service was not detected. If the location entered above is accurate, please check here for instructions on preparing your installation.";
            
            // add custom link
            NSRange r = [self.errorMessageLabel.text rangeOfString:@"check here"];
            [self.errorMessageLabel addLinkToURL:[NSURL URLWithString:@"https://labs.outsystems.net/Native"] withRange:r];
            [self.errorMessageLabel setUserInteractionEnabled:YES];
            self.errorMessageLabel.delegate = self;
            
            [_errorMessageLabel setHidden:NO];
        }
        
        [_connectionActivityIndicator stopAnimating];
        [_errorMessageLabel setHidden:NO];
        [_goButton setHidden:NO];
        [self.tryDemoButton setEnabled:YES];
        
        // shake on error
        CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
        anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
        anim.autoreverses = YES ;
        anim.repeatCount = 2.0f ;
        anim.duration = 0.07f ;
        
        [self.view.layer addAnimation:anim forKey:nil ] ;
    }
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)gotoOutSystems:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.outsystems.com"]];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"GoToLoginSegue"]) {
        self.navigationController.navigationBar.hidden = NO;
        
        LoginScreenController *loginViewController = [segue destinationViewController];
        loginViewController.infrastructure = self.infrastructure;
        loginViewController.deepLinkController = self.deepLinkController;
    }
    
    if ([[segue identifier] isEqualToString:@"tryDemoSegue"]) {
        self.navigationController.navigationBar.hidden = NO;
        
        
        NSString *UDID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        // set the url to register the device push notifications token (in case it is received later)
        [OutSystemsAppDelegate setURLForPushNotificationTokenRegistration:[NSString stringWithFormat:@"%@?&deviceHwId=%@&device=",
                                                                           [DemoInfrastructure getHostnameForService:@"registertoken"],
                                                                           UDID]];
        
        [OutSystemsAppDelegate registerPushToken]; // send the push token to the server
        
        ApplicationTileListController *appViewController = [segue destinationViewController];
        appViewController.isDemoEnvironment = YES;
        [appViewController.applicationList removeAllObjects]; // clear previous list of apps to force a refresh from the server
    }
}



-(void)resetCredentials{
    [self setUserCredentioals:nil password:nil];
}

-(Infrastructure*)getInfrastructure{
    return self.infrastructure;
}

-(void)setUserCredentioals:(NSString*)user password: (NSString*)pass{
    self.infrastructure.username = user;
    self.infrastructure.password = pass;
}

-(void)validateHostname{
    [self.goButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
}

@end
