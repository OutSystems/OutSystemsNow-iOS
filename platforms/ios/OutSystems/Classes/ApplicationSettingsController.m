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


+(NSString*)backgroundColor{
    NSDictionary *settings = [self getApplicationSettings];
    NSString *result = nil;
    
    if(settings){
        result = [settings valueForKey:@"BackgroundColor"];
    }
    
    return result;
}

+(NSString*)foregroundColor{
    NSDictionary *settings = [self getApplicationSettings];
    NSString *result = nil;
    
    if(settings){
        result = [settings valueForKey:@"ForegroundColor"];
    }
    
    return result;
}

+(NSString*)tintColor{
    NSDictionary *settings = [self getApplicationSettings];
    NSString *result = nil;
    
    if(settings){
        result = [settings valueForKey:@"TintColor"];
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
    return nil;
}


@end
