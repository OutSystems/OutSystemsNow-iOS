//
//  LoginApplication.m
//  OutSystems
//
//  Created by engineering on 08/01/15.
//
//

#import "LoginApplication.h"
#import "OutSystemsAppDelegate.h"


@implementation LoginApplication

@dynamic appName;
@dynamic appDesc;
@dynamic appImage;
@dynamic appPath;
@dynamic hostname;
@dynamic username;
@dynamic preloader;

+ (LoginApplication *) initWithJSON:(NSDictionary *) appJsonData forInfrastructure:(Infrastructure *) infrastructure{
    
    
    NSManagedObjectContext* moc = [(OutSystemsAppDelegate*)([[UIApplication sharedApplication] delegate]) managedObjectContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LoginApplication" inManagedObjectContext:moc];
    
    LoginApplication *loginApp = [[LoginApplication alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];    
    
    loginApp.hostname = infrastructure.hostname;
    loginApp.username = infrastructure.username;
    
    loginApp.appName = [appJsonData objectForKey:@"name"];
    loginApp.appDesc = [appJsonData objectForKey:@"description"];
    loginApp.appPath = [appJsonData objectForKey:@"path"];
    loginApp.appImage = [appJsonData objectForKey:@"imageId"];
    
    NSObject *preloader = [appJsonData objectForKey:@"preloader"];
    if([preloader isKindOfClass:[NSNumber class]]){
        NSNumber* temp = (NSNumber*)preloader;
        loginApp.preloader = [temp intValue] > 0;
        
    }
    else{
        loginApp.preloader = NO;
    }
    
    
    return loginApp;
}

+ (LoginApplication *) initWithApplication:(Application *) application forInfrastructure:(Infrastructure *) infrastructure {
    
    NSManagedObjectContext* moc = [(OutSystemsAppDelegate*)([[UIApplication sharedApplication] delegate]) managedObjectContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LoginApplication" inManagedObjectContext:moc];
    
    LoginApplication *loginApp = [[LoginApplication alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    
    loginApp.hostname = infrastructure.hostname;
    loginApp.username = infrastructure.username;
    
    loginApp.appName = application.name;
    loginApp.appDesc = application.appDescription;
    loginApp.appImage = application.imageId;
    loginApp.appPath = application.path;
    
    loginApp.preloader = application.preloader;
    
    return loginApp;
}

@end
