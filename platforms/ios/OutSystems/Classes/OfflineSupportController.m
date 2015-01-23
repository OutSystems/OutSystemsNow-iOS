//
//  OfflineSupportController.m
//  OutSystems
//
//  Created by engineering on 08/01/15.
//
//

#import <Foundation/Foundation.h>
#import "OfflineSupportController.h"
#import "LoginApplication.h"
#import "Application.h"
#import "Infrastructure.h"
#import "Reachability.h"
#import "ApplicationTileListController.h"
#import "ApplicationViewController.h"
#import "LoginScreenController.h"
#import "OutSystemsAppDelegate.h"

@implementation OfflineSupportController


static BOOL newSession;
static BOOL offlineSession = YES;

static NSMutableDictionary *previousSession;


static NSString * osFailedURL;
static UIWebView * osWebView;
static Application * osApplication;
static NSData * _loginResponseData;

#pragma mark - Database handler

+ (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}


+(void)addApplications:(NSArray *)applications forInfrastructure:(Infrastructure*)infrastructure{
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LoginApplication"];
    
    NSString *hostname = infrastructure.hostname;
    NSString *username = infrastructure.username;
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"hostname == %@ && username == %@", hostname, username]];
    NSMutableArray *loginApplications = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    for (LoginApplication *loginApp in loginApplications){
        [managedObjectContext deleteObject:loginApp];
    }
    
    for(int i = 0; i < [applications count]; i++){
        [LoginApplication initWithJSON:applications[i] forInfrastructure:infrastructure];        
    }
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}


+(NSArray*)getLoginApplications:(Infrastructure*)infrastructure{
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LoginApplication"];
    
    NSString *hostname = infrastructure.hostname;
    NSString *username = infrastructure.username;
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"hostname == %@ && username == %@", hostname, username]];
    NSMutableArray *loginApplications = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    
    NSMutableArray *applications = [NSMutableArray array];
    
    for (LoginApplication *loginApp in loginApplications) {
        
        NSMutableDictionary *appData = [NSMutableDictionary new];
        [appData setValue:loginApp.hostname forKey:@"hostname"];
        [appData setValue:loginApp.username forKey:@"username"];
        [appData setValue:loginApp.appName forKey:@"name"];
        [appData setValue:loginApp.appDesc forKey:@"description"];
        [appData setValue:loginApp.appPath forKey:@"path"];
        [appData setValue:loginApp.appImage forKey:@"imageId"];
        
        Application *app = [Application initWithDictionary:appData];
        
        [applications addObject:app];
    }
    
    return applications;
}



+(void) getPreviousSession{
    
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Infrastructure"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO];;
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];

    NSMutableArray *environments = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    Infrastructure *infrastructure  = [environments firstObject];
    
    if(!previousSession){
        previousSession = [NSMutableDictionary new];
    }
    else{
        [previousSession removeAllObjects];
    }
    
    [previousSession setObject:infrastructure.hostname forKey:@"hostname"];
    [previousSession setObject:infrastructure.username forKey:@"username"];
    [previousSession setObject:infrastructure.name forKey:@"name"];
    [previousSession setObject:infrastructure.password forKey:@"password"];
    [previousSession setObject:[NSNumber numberWithBool:infrastructure.isJavaServer] forKey:@"isJavaServer"];
    [previousSession setObject:infrastructure.lastUsed forKey:@"lastUsed"];
    
}


#pragma mark - Offline

+(BOOL)isNetworkAvailable:(Infrastructure*)infrastructure{
    
    if ([[Reachability reachabilityWithHostName:infrastructure.hostname] currentReachabilityStatus] == NotReachable) {
        return NO;
    }
    
    return YES;
}


+(BOOL)hasValidCredentials:(Infrastructure*)infrastructure{
    
    NSArray *loginApplications = [self getLoginApplications:infrastructure];
    
    return [loginApplications count] > 0;
}



+(void)retryWebViewAction:(UIWebView*)webView failedURL:(NSString *)failedURL forApplication:(Application*)application andInfrastructure:(Infrastructure*)infrastructure{
    
    osWebView = webView;
    osFailedURL = failedURL;
    osApplication = application;
    _loginResponseData = nil;
    
    BOOL networkAvailable = [self isNetworkAvailable:infrastructure];
    if(networkAvailable){
        [self loginIfNeeded:infrastructure];
    }
    else{
        [self reloadWebView];
    }
    
}

+(void)reloadWebView{
    if(osFailedURL != nil){
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:osFailedURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
        [osWebView loadRequest:request];
    }
    else {
        NSURL *url = [[osWebView request] URL];
        if(url != nil && url.absoluteString.length > 0){
            [osWebView reload];
        }
        else{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/", osApplication.path]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
            [osWebView loadRequest:request];
        }
    }
}


+(void)loginIfNeeded:(Infrastructure*)infrastructure{
    if(offlineSession){
        
        _loginResponseData = nil;
        
        int timeoutInSeconds = 30;

        // get the device dimensions
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        
        NSURL *myURL = [NSURL URLWithString:[infrastructure getHostnameForService:@"login"]];
        
        NSString *deviceUDID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        NSString *post = [NSString stringWithFormat:@"username=%@&password=%@&devicetype=%@&screenWidth=%d&screenHeight=%d&deviceHwId=%@",
                          [infrastructure.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                          [infrastructure.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                          @"ios",
                          (int)screenBounds.size.width,
                          (int)screenBounds.size.height,
                          deviceUDID]; // hardware unique idenfifier
        
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
        
        NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:myURL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeoutInSeconds];
        
        [myRequest setHTTPMethod:@"POST"];
        [myRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [myRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [myRequest setHTTPBody:postData];
        
        NSLog(@"Logging in: %@", myURL);
        
        [NSURLConnection connectionWithRequest:myRequest delegate:self];            
        
        // set the url to register the device push notifications token (in case it is received later)
        [OutSystemsAppDelegate setURLForPushNotificationTokenRegistration:[NSString stringWithFormat:@"%@?&deviceHwId=%@&device=",
                                                                           [infrastructure getHostnameForService:@"registertoken"],
                                                                           deviceUDID]];

    }
    else{
        [self reloadWebView];
    }
}

#pragma mark - Connection

+ (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}


+ (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
    NSInteger errorCode = httpResponse.statusCode;
    NSString *fileMIMEType = [[httpResponse MIMEType] lowercaseString];
    NSLog(@"response is %ld, %@", (long)errorCode, fileMIMEType);
}

+ (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    _loginResponseData = data;
}

+ (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    [self reloadWebView];
}

+ (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    NSLog(@"connection finished");

    
    NSError *e = nil;
    NSDictionary *response = nil;
    BOOL success = NO;
    NSString *moduleVersion;
    
    if(_loginResponseData != nil) {
        response = [NSJSONSerialization JSONObjectWithData:_loginResponseData options:NSJSONReadingMutableContainers error:&e];
        NSLog(@"obj: %@ ; error: %@", response,e);
        if([[response objectForKey:@"success"] isKindOfClass:[NSNumber class]]) {
            success = [[response objectForKey:@"success"] boolValue];
        }
    }
    
    // check OutSystemsNowService compatibility
    if([[response objectForKey:@"version"] isKindOfClass:[NSString class]]) {
        moduleVersion = [response objectForKey:@"version"];
    }
    
    if(moduleVersion == nil || [moduleVersion rangeOfString:OutSystemsNowRequiredVersion].location != 0) {
        success = NO;
        [response setValue:@"Incompatible module version in your installation, please contact your system administrator to update the OutSystems Now modules" forKey:@"errorMessage"];
    }
    
    if(success) {
        offlineSession = NO;
    }
    
    [self reloadWebView];
}



# pragma mark - Session
+(void)prepareForLogin{
    newSession = NO;
    offlineSession = YES;
    
    osWebView = nil;
    osFailedURL = nil;
    osApplication = nil;
    _loginResponseData = nil;
    
    [self getPreviousSession];
}

+(void)checkCurrentSession:(Infrastructure*)infrastructure{
    newSession = YES;
    offlineSession = NO;
    
    if(previousSession){
        NSString *previousHostname = [previousSession valueForKey:@"hostname"];
        NSString *previousUsername = [previousSession valueForKey:@"username"];
        
        BOOL sameEnvironment = [infrastructure.hostname isEqualToString:previousHostname];
        BOOL sameUser = [infrastructure.username isEqualToString:previousUsername];
        
        newSession = !(sameEnvironment && sameUser);
        NSLog(@"NewSession: %@", newSession ? @"YES" : @"NO");
    }
}


# pragma mark - Cache
+(void) clearCacheIfNeeded
{
    if (newSession){
  
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        
        NSString *cacheDir=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *nsurlDir = [[NSString alloc] initWithFormat:@"%@/com.outsystems.app", cacheDir];
        NSFileManager  *manager = [NSFileManager defaultManager];
        
        
        // grab all the files in the documents dir
        NSArray *allFiles = [manager contentsOfDirectoryAtPath:nsurlDir error:nil];
        
        // filter the array for only sqlite files
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.db'"];
        NSArray *dbFiles = [allFiles filteredArrayUsingPredicate:fltr];
        
        // use fast enumeration to iterate the array and delete the files
        for (NSString *dbFile in dbFiles)
        {
            NSError *error = nil;
            [manager removeItemAtPath:[nsurlDir stringByAppendingPathComponent:dbFile] error:&error];
            if (error != nil) {
                NSLog(@"Error:%@", [error description]);
            } else {
                NSLog(@"DB FILE Cleared: %@", dbFile);
            }
        }
        
        
        NSError *error = nil;
        [manager removeItemAtPath:[nsurlDir stringByAppendingString:@"/osurlcache"] error:&error];
        if (error != nil) {
            NSLog(@"Error:%@", [error description]);
        } else {
            NSLog(@"Dir Cleared");
        }
  
    }
}

@end
