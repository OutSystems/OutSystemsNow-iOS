//
//  DeepLinkController.m
//  OutSystems
//
//  Created by engineering on 14/10/14.
//
//

#import <Foundation/Foundation.h>
#import "DeepLinkController.h"
#import "HubAppViewController.h"
#import "LoginScreenController.h"
#import "ApplicationTileListController.h"
#import "ApplicationViewController.h"
#import "OutSystemsAppDelegate.h"


@implementation DeepLinkController

-(id)init{
    self = [super init];
    
    if(!self.deepLinkSettings){
        self.deepLinkSettings  = [[DeepLink alloc] init];
    }
    
    return self;
}

-(void)createSettingsFromURL:(NSURL *)url{
    
    if(!url){
        [self.deepLinkSettings invalidate];
        return;
    }
    
    NSString * host = [url host];
    NSString * path = [url path];
    NSString * query = [url query];
    
    self.destinationApp = nil;
    
    [self.deepLinkSettings addEnvironment:host operation:path parameters:query];
    [self createApplication];
}

-(void)createApplication{

    if(![self hasApplicationUrl]){
        self.destinationApp = nil;
        return;
    }
    
    NSString *hostname = self.deepLinkSettings.environment;
    NSString *url = [self.deepLinkSettings getParameterWithKey:kDLUrlParameter];
    
    // Ensure hat the url format its correct
    NSString *applicationName = [url stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    
    // Get the application's name
    if ([applicationName rangeOfString:@"/"].location != NSNotFound){
        while ([applicationName hasPrefix:@"/"]){
            if([applicationName length] > 1)
                applicationName = [applicationName substringFromIndex:1];
            else
                applicationName = @"";
        }
        
        url = applicationName;
        
        NSRange slashPosition = [applicationName rangeOfString:@"/"];
        
        if(slashPosition.location > 0)
            applicationName = [applicationName substringToIndex:slashPosition.location];
        
        NSLog(@"Application Name - %@",applicationName);
        NSLog(@"URL - %@",url);
        
    }
    
    
    NSNumber *imageId = [NSNumber numberWithInt:-1];
        
    NSMutableDictionary *application = [[NSMutableDictionary alloc] init];
    [application setObject:applicationName forKey:@"name"];
    [application setObject:applicationName forKey:@"description"];
    [application setObject:imageId forKey:@"imageId"];
    [application setObject:url forKey:@"path"];
        

    self.destinationApp = [Application initWithJSON:application forHost:hostname];
    
}


-(BOOL)hasValidSettings{
    return self.deepLinkSettings && self.deepLinkSettings.isValid;
}


-(DeepLink*)getSettings{
    return self.deepLinkSettings;
}

-(BOOL)hasCredentials{
    NSString *user = [self.deepLinkSettings getParameterWithKey:kDLUsernameParameter];
    NSString *pass = [self.deepLinkSettings getParameterWithKey:kDLPasswordParameter];

    return [user length] > 0 && [pass length] > 0;
}

-(BOOL)hasUsername{
    NSString *user = [self.deepLinkSettings getParameterWithKey:kDLUsernameParameter];
    return [user length] > 0;
}

-(BOOL)hasApplicationUrl{
    NSString *url = [self.deepLinkSettings getParameterWithKey:kDLUrlParameter];
    return [url length] > 0;
}

-(BOOL)hasApplication{
    return self.destinationApp != nil;
}

-(void)resolveOperation:(UIViewController*)source{ 
    
    if(!source ){
        NSLog(@"ViewController not found!");
        return;
    }
    
    
    switch (self.getSettings.operation) {
        case dlLoginOperation:
            
            // HubAppViewController
            if([source isKindOfClass:[HubAppViewController class]]){
                HubAppViewController *hubAppVC = (HubAppViewController *)source;
                
                // Go to login page if it has credentials or username
                if([self hasCredentials] || [self hasUsername]){
                    
                    if([OutSystemsAppDelegate hasAutoLoginPerformed] == NO){
                        [hubAppVC validateHostname];
                    }
                }
                
                // Otherwise, setup Environment
                // Do nothing
                
            }
            else{
                
                // LoginScreenController
                if([source isKindOfClass:[LoginScreenController class]]){
                    
                    LoginScreenController *loginVC = (LoginScreenController *)source;
                    if(![self hasCredentials]){
                        if([self hasUsername]){
                            // Login page
                            NSString *user = [self.deepLinkSettings getParameterWithKey:kDLUsernameParameter];
                            
                            [loginVC setUserCredentials:user password:nil];
                            
                            [OutSystemsAppDelegate setAutoLoginPerformed];
                        }
                    }
                    else{
                        // Login action with credentials
                        
                        NSString *user = [self.deepLinkSettings getParameterWithKey:kDLUsernameParameter];
                        NSString *pass = [self.deepLinkSettings getParameterWithKey:kDLPasswordParameter];
                        
                        [loginVC setUserCredentials:user password:pass];
                        
                    }
                }
            }
            
            break;

        case dlOpenUrlOperation:

            // HubAppViewController
            if([source isKindOfClass:[HubAppViewController class]]){
                HubAppViewController *hubAppVC = (HubAppViewController *)source;
                
                if([OutSystemsAppDelegate hasAutoLoginPerformed] == NO){
                    [hubAppVC validateHostname];
                }
                
            }
            else{
                
                // LoginScreenController
                if([source isKindOfClass:[LoginScreenController class]]){
                    
                    LoginScreenController *loginVC = (LoginScreenController *)source;
                    
                    if([self hasCredentials]){
                        // Login action with credentials
                        
                        NSString *user = [self.deepLinkSettings getParameterWithKey:kDLUsernameParameter];
                        NSString *pass = [self.deepLinkSettings getParameterWithKey:kDLPasswordParameter];
                        
                        [loginVC setUserCredentials:user password:pass];
                    }
                    
                }
                else{

                    if ([source isKindOfClass:[ApplicationTileListController class]]){
                        ApplicationTileListController* appListVC = (ApplicationTileListController*)source;
                        
                        UINavigationController *navControler = appListVC.navigationController;
                        UIStoryboard *storyboard = appListVC.storyboard;
                        
                        if(navControler && storyboard) {
                            
                            ApplicationViewController *targetViewControler = [storyboard instantiateViewControllerWithIdentifier:@"ApplicationViewController"];
                            
                            
                            targetViewControler.isSingleApplication = NO;
                            
                            targetViewControler.application = self.destinationApp;
                            
                            [navControler pushViewController:targetViewControler animated:NO];
                            
                            [self.deepLinkSettings invalidate];
                        }
                        
                    }
                }
            }

            
            break;
        default:
            // Invalid operation. Ignore!
            break;
    }

  
}


@end