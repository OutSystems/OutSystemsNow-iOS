//
//  Application.m
//  HubApp
//
//  Created by engineering on 03/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import "Application.h"
#import "OutSystemsAppDelegate.h"


@implementation Application

@dynamic name;
@dynamic appDescription;
@dynamic path;
@dynamic imageId;
@dynamic feedbackActive;
@dynamic preloader;

+ (Application *) initWithJSON:(NSDictionary *) appJsonData forHost:(NSString *) hostname {
    
    NSManagedObjectContext* moc = [(OutSystemsAppDelegate*)([[UIApplication sharedApplication] delegate]) managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Application" inManagedObjectContext:moc];
    
    Application *app = [[Application alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    
    [appJsonData objectForKey:@"name"];
    
    app.name = [appJsonData objectForKey:@"name"];
    app.appDescription = [appJsonData objectForKey:@"description"];
    
    NSString *appPath = [NSString stringWithFormat:@"https://%@/%@", hostname, [appJsonData objectForKey:@"path"]];
    
    app.path = appPath;
    app.imageId = [appJsonData objectForKey:@"imageId"];
    
    
    NSObject* feedback = [appJsonData objectForKey:@"feedbackActive"];
    
    if([feedback isKindOfClass:[NSNumber class]]){
        NSNumber* temp = (NSNumber*)feedback;
        app.feedbackActive = [temp intValue] > 0;
        
    }
    else{
        app.feedbackActive = NO;
    }
    
    
    NSObject *preloader = [appJsonData objectForKey:@"preloader"];
    if([preloader isKindOfClass:[NSNumber class]]){
        NSNumber* temp = (NSNumber*)preloader;
        app.preloader = [temp intValue] > 0;
        
    }
    else{
        app.preloader = NO;
    }
    
    
    
    return app;
}

+(Application *) initWithDictionary:(NSDictionary *) appData{
    NSManagedObjectContext* moc = [(OutSystemsAppDelegate*)([[UIApplication sharedApplication] delegate]) managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Application" inManagedObjectContext:moc];
    
    Application *app = [[Application alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:moc];
    
    [appData objectForKey:@"name"];
    
    app.name = [appData objectForKey:@"name"];
    app.appDescription = [appData objectForKey:@"description"];
    app.path = [appData objectForKey:@"path"];
    app.imageId = [appData objectForKey:@"imageId"];
    
    
    NSObject* feedback = [appData objectForKey:@"feedbackActive"];
    
    if([feedback isKindOfClass:[NSNumber class]]){
        NSNumber* temp = (NSNumber*)feedback;
        app.feedbackActive = [temp intValue] > 0;
        
    }
    else{
        app.feedbackActive = NO;
    }
    
    NSObject *preloader = [appData objectForKey:@"preloader"];
    if([preloader isKindOfClass:[NSNumber class]]){
        NSNumber* temp = (NSNumber*)preloader;
        app.preloader = [temp intValue] > 0;
        
    }
    else{
        app.preloader = NO;
    }
    
    
    return app;
}

-(NSDictionary*) toDictionary{
    NSMutableDictionary *result = [NSMutableDictionary new];


    [result setObject:self.name forKey:@"name"];
    [result setObject:self.appDescription forKey:@"description"];
    [result setObject:self.path forKey:@"path"];
    [result setObject:self.imageId forKey:@"imageId"];
    
    [result setObject:[NSNumber numberWithBool:self.feedbackActive] forKey:@"feedbackActive"];
    [result setObject:[NSNumber numberWithBool:self.preloader] forKey:@"preloader"];
    

    return result;
}

@end
