//
//  ApplicationSettingsController.m
//  OutSystems
//
//  Created by engineering on 21/07/15.
//
//

#import "ApplicationSettingsController.h"
#import "HubAppViewController.h"
#import "LoginScreenController.h"
#import "ApplicationTileListController.h"
#import "ApplicationViewController.h"
#import "OutSystemsAppDelegate.h"

@implementation ApplicationSettingsController


# pragma mark - Info.plist variables
+(NSDictionary*)getApplicationSettings{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"OSNowApplicationSettings"];
}

# pragma mark - Native Settings

+(BOOL)skipNativeLogin{
    
    NSDictionary *settings = [self getApplicationSettings];
    
    if(settings){
        BOOL result = [[settings valueForKey:@"SkipNativeLogin"] boolValue];
        return result;
    }
    
    return NO;
}

+(BOOL)skipApplicationList{
    NSDictionary *settings = [self getApplicationSettings];
    
    if(settings){
        BOOL result = [[settings valueForKey:@"SkipApplicationList"] boolValue];
        return result;
    }
    
    return NO;
}

+(BOOL)hideNavigationBar{
    NSDictionary *settings = [self getApplicationSettings];
    
    if(settings){
        BOOL result = [[settings valueForKey:@"HideNavigationBar"] boolValue];
        return result;
    }
    
    return NO;
}

+(NSString*)defaultHostname{
    NSDictionary *settings = [self getApplicationSettings];
    NSString *result = nil;
    
    if(settings){
        result = [settings valueForKey:@"DefaultHostname"];
    }
    
    return result;
}

+(NSString*)defaultApplicationURL{
    NSDictionary *settings = [self getApplicationSettings];
    NSString *result = nil;
    
    if(settings){
        result = [settings valueForKey:@"DefaultApplicationURL"];
    }
    
    return result;
}


+(UIColor*)backgroundColor{
    NSDictionary *settings = [self getApplicationSettings];
    UIColor *result = nil;
    
    if(settings){
        NSString *strColor = [settings valueForKey:@"BackgroundColor"];
        if([strColor length] == 7)
            result = [self colorFromHexString:strColor];
    }
    
    return result;
}

+(UIColor*)foregroundColor{
    NSDictionary *settings = [self getApplicationSettings];
    UIColor *result = nil;
    
    if(settings){
        NSString *strColor = [settings valueForKey:@"ForegroundColor"];
        if([strColor length] == 7)
            result = [self colorFromHexString:strColor];
    }
    
    return result;
}

+(UIColor*)tintColor{
    NSDictionary *settings = [self getApplicationSettings];
    UIColor *result = nil;
    
    if(settings){
        NSString *strColor = [settings valueForKey:@"TintColor"];
        if([strColor length] == 7)
            result = [self colorFromHexString:strColor];
    }
    
    return result;
}


# pragma mark - Core Data

+ (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

+(Infrastructure*) getOrCreateInfrastructure: (NSString*) hostname {
    Infrastructure *infrastructure;
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Infrastructure"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO];;
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"hostname == %@", hostname]];
    NSMutableArray *environments = nil;
    
    if(managedObjectContext)
        environments = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    if([environments count] > 0) {
        infrastructure = [environments objectAtIndex:0];
        infrastructure.lastUsed = [NSDate date];
        
    } else {
        infrastructure = [NSEntityDescription insertNewObjectForEntityForName:@"Infrastructure" inManagedObjectContext:[self managedObjectContext]];
        infrastructure.hostname = hostname;
        infrastructure.name = hostname;
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


# pragma mark - Infrastructure
+(void)checkInfrastructure:(Infrastructure*)infrastructure{
    
    NSURL *url = [NSURL URLWithString:[infrastructure getHostnameForService:@"infrastructure"]];
    
    NSURLRequest *myRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5];
    [NSURLConnection connectionWithRequest:myRequest delegate:self];    
}



+ (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

+ (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSArray *trustedHosts = [[NSArray alloc] initWithObjects:@"outsystems.com", @"outsystems.net", @"outsystemscloud.com", nil];
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        for (NSString *trustedHost in trustedHosts) {
            
            // currently trusting all certificates for beta release, remove true condition to validate untrusted certificates with list for trusted servers
            if(true || [challenge.protectionSpace.host rangeOfString:trustedHost options:NSBackwardsSearch].location == (challenge.protectionSpace.host.length - trustedHost.length)) {
                [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
                break;
            }
        }
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
}

+ (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSLog(@"connection finished");
    
}


# pragma mark - Navigation

+(UIViewController*)rootViewController:(UIStoryboard*)storyboard deepLinkController:(DeepLinkController*)deepLinkController{

    BOOL skipNativeLogin = [self skipNativeLogin];
    BOOL skipApplicationList = [self skipApplicationList];
    BOOL hideNavigationBar = [self hideNavigationBar];
    
    NSString *defaultHostname = [self defaultHostname];
    NSString *defaultAppURL = [self defaultApplicationURL];
    
    NSLog(@"SkipNativeLogin: %d",skipNativeLogin);
    NSLog(@"SkipApplicationList: %d",skipApplicationList);
    NSLog(@"HideNavigationBar: %d",hideNavigationBar);
    
    NSLog(@"DefaultHostname: %@",defaultHostname);
    NSLog(@"DefaultApplicationURL: %@",defaultAppURL);
    
    if([defaultHostname length] > 0){
        
        // Get Infrastructure data
        Infrastructure *infrastructure = [self getOrCreateInfrastructure:defaultHostname];
        
        if(skipNativeLogin){
            
            NSString *deviceUDID = [UIDevice currentDevice].identifierForVendor.UUIDString;
            
            [OutSystemsAppDelegate setURLForPushNotificationTokenRegistration:[NSString stringWithFormat:@"%@?&deviceHwId=%@&device=",[infrastructure   getHostnameForService:@"registertoken"],deviceUDID]];
            
            if(skipApplicationList){
                // Push ApplicationViewController
                
                if([defaultAppURL length] > 0){
                    
                    ApplicationViewController *appViewController = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationViewController"];
                    
                    appViewController.isSingleApplication = YES;
                    
                    Application *applicationInfo = nil;
                    
                    if(deepLinkController && [deepLinkController hasValidSettings]){
                        applicationInfo = deepLinkController.destinationApp;
                    }
                    else{
                        NSMutableDictionary *applicationDict = [[NSMutableDictionary alloc] init];
                        [applicationDict setObject:defaultAppURL forKey:@"name"];
                        [applicationDict setObject:defaultAppURL forKey:@"description"];
                        [applicationDict setObject:defaultAppURL forKey:@"path"];
                    
                        applicationInfo = [Application initWithJSON:applicationDict forHost:defaultHostname];
                    }
                    appViewController.application = applicationInfo;
                
                    appViewController.infrastructure = infrastructure;
                    
                    //[self checkInfrastructure:infrastructure];
                    
                    return appViewController;
                }
            }
            else{
                // Push ApplicationTileListController
                
                ApplicationTileListController *appListViewController = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationTileList"];
                
                appListViewController.infrastructure = infrastructure;
                appListViewController.isDemoEnvironment = NO;
                appListViewController.deepLinkController = deepLinkController;
                
                return appListViewController;

            }
            
        }
        else{
            // Push LoginScreenViewController            
            LoginScreenController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginScreen"];
            
            loginViewController.infrastructure = infrastructure;
            loginViewController.deepLinkController = deepLinkController;

            return loginViewController;
        }
    }
    
    
    // Push HubAppViewController
    HubAppViewController *hubAppViewControler = [storyboard instantiateViewControllerWithIdentifier:@"HubScreen"];
    
    hubAppViewControler.deepLinkController = deepLinkController;
    
    return hubAppViewControler;
}


+(UIViewController*)nextViewController:(UIViewController*)currentViewController{
    
    
    UINavigationController *navControler = currentViewController.navigationController;
    UIStoryboard *storyboard = navControler.storyboard;

    BOOL skipNativeLogin = [self skipNativeLogin];
    BOOL skipApplicationList = [self skipApplicationList];
    BOOL hideNavigationBar = [self hideNavigationBar];
    
    NSString *defaultHostname = [self defaultHostname];
    NSString *defaultAppURL = [self defaultApplicationURL];
    
    NSLog(@"SkipNativeLogin: %d",skipNativeLogin);
    NSLog(@"SkipApplicationList: %d",skipApplicationList);
    NSLog(@"HideNavigationBar: %d",hideNavigationBar);
    
    NSLog(@"DefaultHostname: %@",defaultHostname);
    NSLog(@"DefaultApplicationURL: %@",defaultAppURL);
    
    // LoginScreenController
    if([currentViewController isKindOfClass:[LoginScreenController class]]){
        LoginScreenController *loginVC = (LoginScreenController *)currentViewController;
        DeepLinkController *deepLinkController = loginVC.deepLinkController;
        Infrastructure *infrastructure = loginVC.infrastructure;
        
        if(skipApplicationList){
            
            // To skip the application list a default application url must be provided
            if([defaultAppURL length] > 0){

                // Go to ApplicationViewController
                
                ApplicationViewController *appViewController = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationViewController"];
                
                appViewController.isSingleApplication = YES;
                
                Application *applicationInfo = nil;
                
                if(deepLinkController && [deepLinkController hasValidSettings]){
                    applicationInfo = deepLinkController.destinationApp;
                }
                else{
                    NSMutableDictionary *applicationDict = [[NSMutableDictionary alloc] init];
                    [applicationDict setObject:defaultAppURL forKey:@"name"];
                    [applicationDict setObject:defaultAppURL forKey:@"description"];
                    [applicationDict setObject:defaultAppURL forKey:@"path"];
                    
                    applicationInfo = [Application initWithJSON:applicationDict forHost:defaultHostname];
                }
                appViewController.application = applicationInfo;
                
                appViewController.infrastructure = infrastructure;
                
                return appViewController;
            }
        }

        // Otherwise...
        // Go to ApplicationTileListController
        
        ApplicationTileListController *appListViewController = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationTileList"];
        
        appListViewController.infrastructure = infrastructure;
        appListViewController.isDemoEnvironment = NO;
        appListViewController.deepLinkController = deepLinkController;
        
        return appListViewController;
        
    }
    
    
    return nil;
}


# pragma mark - Colors

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}



@end
