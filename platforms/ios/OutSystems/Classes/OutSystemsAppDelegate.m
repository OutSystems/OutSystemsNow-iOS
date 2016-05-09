//
//  HubAppAppDelegate.m
//  HubApp
//
//  Created by engineering on 01/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import "OutSystemsAppDelegate.h"

#import "OSNavigationController.h"

@implementation OutSystemsAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

static BOOL performedAutoLogin = NO;
static NSData *deviceId;
static NSString *urlRegisterForNotifications;
static DeepLink *deepLinkSettings;
static NSMutableArray *trustedHosts;

+ (void) addTrustedHostname:(NSString*) hostname{
    if(!trustedHosts){
        trustedHosts = [[NSMutableArray alloc] initWithObjects:@"outsystems.com",
                                                               @"outsystems.net",
                                                               @"outsystemscloud.com", nil];
    }
    
    if([hostname length] > 0)
        [trustedHosts addObject:hostname];
    
}

+ (BOOL) trustedHostname:(NSString*) hostname{

    for (NSString *trustedHost in trustedHosts) {
        if([trustedHost isEqualToString:hostname]){
            return YES;
        }
    }
    return NO;
}

+ (BOOL) hasAutoLoginPerformed {
    return performedAutoLogin;
}

+ (void) setAutoLoginPerformed {
    performedAutoLogin = YES;
}

+ (void) unsetAutoLoginPerformed{
    performedAutoLogin = NO;
}

+ (void) setURLForPushNotificationTokenRegistration:(NSString *)registerDeviceTokenUrl {
    urlRegisterForNotifications = registerDeviceTokenUrl; // save the url for setting the application token async.
}

+(void) registerPushToken {
    
    if([deviceId length] > 0 && [urlRegisterForNotifications length] > 0) {
        NSString *url = [urlRegisterForNotifications stringByAppendingString:[OutSystemsAppDelegate GetDeviceId]];
        NSURL *myURL = [NSURL URLWithString:url];
        
        NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:myURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
        
        [myRequest setHTTPShouldHandleCookies:NO];
        
        [NSURLConnection connectionWithRequest:myRequest delegate:self];
    }
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[PushNotificationManager pushManager] handlePushReceived:userInfo];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    // Release old user defaults
    NSString *defaultsAppVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppVersion"];
    
    NSString *currentAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    NSRange versionRange = [defaultsAppVersion rangeOfString:currentAppVersion];
    
    if(defaultsAppVersion == nil || versionRange.location == NSNotFound){
        
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        
        [[NSUserDefaults standardUserDefaults] setObject:currentAppVersion forKey:@"AppVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];

    }
    
    [application setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleLightContent];


    // Setup push notifications
    
    //-- Set Notification
    if ([[UIApplication sharedApplication]respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        // iOS 8 Notifications
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        // iOS < 8 Notifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
    
    // Setup Pushwoosh
    
    // set custom delegate for push handling, in our case - view controller
    PushNotificationManager * pushManager = [PushNotificationManager pushManager];
    pushManager.delegate = self;
    
    // handling push on app start
    [[PushNotificationManager pushManager] handlePushReceived:launchOptions];
    
    // make sure we count app open in Pushwoosh stats
    [[PushNotificationManager pushManager] sendAppOpen];
    
    // register for push notifications!
    [[PushNotificationManager pushManager] registerForPushNotifications];
    
    
    // Setup application cache
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:16 * 1024 * 1024 diskCapacity:256 * 1024 * 1024 diskPath:@"osurlcache"];
    
    [NSURLCache setSharedURLCache:URLCache];
    
    // Enable persistent cache
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitStoreWebDataForBackup"];
    
    
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    // Get navigation controller
    OSNavigationController *navigationController = (OSNavigationController *)self.window.rootViewController;
    [navigationController pushRootViewController:nil];
    
    trustedHosts = [[NSMutableArray alloc] initWithObjects:@"outsystems.com", @"outsystems.net", @"outsystemscloud.com", nil];
    
    // Override point for customization after application launch.
    return YES;
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // Bring login screen back to view and perform auto login agains
    //UINavigationController *navigationController = (UINavigationController *) self.window.rootViewController;
    
    //if([navigationController.viewControllers count] > 2) { // pop back to the login screen
    //    performedAutoLogin = NO; // force the auto login
    //    [navigationController popToViewController:[navigationController.viewControllers objectAtIndex:1] animated:YES];
    //}
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[PushNotificationManager pushManager] handlePushRegistration:deviceToken];
    
    deviceId = deviceToken;
    
    NSLog(@"My token is: %@", deviceToken);
    
    [OutSystemsAppDelegate registerPushToken]; // send the push token to the OutSystems server, if set

}

+(NSString *)GetDeviceId {
    
    NSMutableString *string = [NSMutableString stringWithCapacity:[deviceId length]*2];
    const unsigned char *dataBytes = [deviceId bytes];
    for (NSInteger idx = 0; idx < [deviceId length]; ++idx) {
        [string appendFormat:@"%02x", dataBytes[idx]];
    }
    
    return string;
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[PushNotificationManager pushManager] handlePushRegistrationFailure:error];
    NSLog(@"Failed to get token, error: %@", error);
}


- (void) onPushAccepted:(PushNotificationManager *)pushManager withNotification:(NSDictionary *)pushNotification {
    NSLog(@"Push notification received");
    
    NSMutableDictionary *remoteNotificationInfo = nil;
    
    @try {
        NSString *link = [pushNotification objectForKey:@"l"];
        
        if(link){
            // If a link is defined in the push notification data, the experience ends here :(
            return;
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to parse push notification extra data");
    }

    
    @try {
        
        NSString *jsonString = [pushNotification objectForKey:@"u"];
        
        if(jsonString){
            NSError *jsonError;
            NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            remoteNotificationInfo = [NSJSONSerialization JSONObjectWithData:objectData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&jsonError];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to parse push notification extra data");
    }
    
    if(remoteNotificationInfo){

        NSString *deeplink = [remoteNotificationInfo valueForKey:@"deeplink"];
        
        if(deeplink && [deeplink length] > 0){
            
            // { "deeplink": "environment/module/Screen?parameters" }
            
            NSRange range = [deeplink rangeOfString:@"/"];
            
            NSString *environment = [deeplink substringToIndex:range.location];
            NSString *url = [deeplink substringFromIndex:range.location+1];
            NSString *protocol = @"OSNow";
            
            NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
            NSArray* urlTypes = [infoDict objectForKey:@"CFBundleURLTypes"];
            if(urlTypes){
                
                NSArray* urlSchemes = [urlTypes[0] objectForKey:@"CFBundleURLSchemes"];
                
                if([urlSchemes count] > 0){
                    protocol = urlSchemes[0];
                }
                
                if(!protocol){
                    protocol = @"OSNow";
                }
            }
            
            // OSNow://labsdev.outsystems.net/openurl/?username=&password=&url=
            NSURL *appURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/openurl/?url=%@",protocol,environment,url]];
            
            // Get the settings from the URL
            if(!self.deepLinkController){
                self.deepLinkController = [[DeepLinkController alloc] init];
            }
            
            [self.deepLinkController createSettingsFromURL:appURL];
            
            performedAutoLogin = NO;
            
            // Get navigation controller
            UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
            
            NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: navigationController.viewControllers];
            [navigationArray removeAllObjects]; // This is just for remove all view controller from navigation stack.
            
            // Passing the Deep Link settings
            [(OSNavigationController *)navigationController pushRootViewController:self.deepLinkController];
            
        }
        
    }
    
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    performedAutoLogin = NO;
    
    // Get the settings from the URL
    if(!self.deepLinkController){
        self.deepLinkController = [[DeepLinkController alloc] init];
    }

    [self.deepLinkController createSettingsFromURL:url];
    
    // Get navigation controller
    OSNavigationController *navigationController = (OSNavigationController *)self.window.rootViewController;
    [navigationController pushRootViewController:self.deepLinkController];
    
    return YES;
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OutAppData" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"HubApp.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
