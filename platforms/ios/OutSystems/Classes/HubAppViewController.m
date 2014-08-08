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

@interface HubAppViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *connectionActivityIndicator;

@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIButton *tryDemoButton;
@property (weak, nonatomic) IBOutlet UIButton *explainURLButton;
@property (weak, nonatomic) IBOutlet UIInsetTextField *environmentHostname;

@property (strong, nonatomic) NSMutableArray *environments;

@property (strong, nonatomic) Infrastructure *infrastructure;
@property (strong, nonatomic) Infrastructure *demoInfrastructure;

@property (weak, nonatomic) IBOutlet UILabel *accessYourAppLabel;
@property (weak, nonatomic) IBOutlet UILabel *explainURLLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksLabel;
@property (weak, nonatomic) IBOutlet UIView *helpView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *helpURLHeightContraint;

@property (weak, nonatomic) NSData *loginResponseData;
@property NSArray* trustedHosts;
@property NSInteger connectionErrorCode;
@property BOOL tryAnotherStack;

@end

@implementation HubAppViewController

- (void) viewWillAppear:(BOOL)animated {
    
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.toolbar.hidden = YES;
    
    // Fetch the environments from persistent data store
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Infrastructure"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO];;
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    self.environments = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    if(self.environments.count > 0) {
        
        self.infrastructure = [self.environments objectAtIndex:0];
        self.environmentHostname.text = self.infrastructure.hostname;
        
        // check if we have the login and password for that infrasctructure
        if([self.infrastructure.username length] > 0 && [self.infrastructure.password length] > 0) {
            
            // execute the login automatically if not done yet
            if( [OutSystemsAppDelegate hasAutoLoginPerformed] == NO) {
                UIStoryboard *storyboard = self.storyboard;
                LoginScreenController *targetViewControler = [storyboard instantiateViewControllerWithIdentifier:@"LoginScreen"];
                UINavigationController *navControler = self.navigationController;
        
                if(navControler) {
                    targetViewControler.infrastructure = self.infrastructure;
                    [navControler pushViewController:targetViewControler animated:NO];
                }
            }
        }
    }
    
}

- (void)viewDidLoad {
    
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
    self.tryAnotherStack = NO;
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

- (IBAction)OnGoClick:(UIButton *)sender {
    
    [self.connectionActivityIndicator startAnimating];
    [self.errorMessageLabel setHidden:YES];
    [self.goButton setHidden:YES];
    [self.tryDemoButton setEnabled:NO];
    
    
    if(self.environmentHostname.text.length > 0) {
        NSString *hostname = self.environmentHostname.text;
        
        NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Infrastructure"];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO];;
        
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"hostname == %@", hostname]];
        self.environments = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
        
        if( self.environments.count > 0) {
            self.infrastructure = [self.environments objectAtIndex:0];
            self.infrastructure.lastUsed = [NSDate date];
            
        } else {
            
            // Create a new managed object
            self.infrastructure = [NSEntityDescription insertNewObjectForEntityForName:@"Infrastructure" inManagedObjectContext:[self managedObjectContext]];
            self.infrastructure.hostname = hostname;
            self.infrastructure.name = self.infrastructure.name;
            self.infrastructure.lastUsed = [NSDate date];
            self.infrastructure.isJavaServer = NO; // set default to NO
        }
        
        NSError *error = nil;
        // Save the object to persistent store
        if (![[self managedObjectContext] save:&error]) {
            NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        
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
    self.errorMessageLabel.text = @"Error trying to connect to the provided network, please make sure you have an internet connection";
    
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
        
        [_connectionActivityIndicator stopAnimating];
        [_goButton setHidden:NO];
        [_errorMessageLabel setHidden:YES];
        [self.tryDemoButton setEnabled:YES];
        
        [self performSegueWithIdentifier:@"GoToLoginSegue" sender:self];
        
    } else {
        if(self.connectionErrorCode == 404 && self.tryAnotherStack == NO) {
            
            // failed to contact the server, look for java version or the OutSystems App service is not installed
            self.tryAnotherStack = YES;
            self.infrastructure.isJavaServer = !self.infrastructure.isJavaServer;
            [self connectToInfrastructure:self.infrastructure];
            
            return; // retry the java version and end this try here (don't shake on this error)
            
        } else if(self.tryAnotherStack) {
            // no service found!
            self.errorMessageLabel.text = @"OutSystems Application service was not found on the provided network, please contact your system administrator";
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

- (IBAction)gotoOutSystems:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.outsystems.com"]];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"GoToLoginSegue"]) {
        self.navigationController.navigationBar.hidden = NO;
        
        LoginScreenController *loginViewController = [segue destinationViewController];
        loginViewController.infrastructure = self.infrastructure;
    }
    
    if ([[segue identifier] isEqualToString:@"tryDemoSegue"]) {
        self.navigationController.navigationBar.hidden = NO;
        
        ApplicationTileListController *appViewController = [segue destinationViewController];
        appViewController.infrastructure = self.demoInfrastructure;
        appViewController.isDemoEnvironment = YES;
        [appViewController.applicationList removeAllObjects]; // clear previous list of apps to force a refresh from the server
    }
}

@end
