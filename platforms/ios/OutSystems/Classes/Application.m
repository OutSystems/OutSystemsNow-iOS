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
    
    return app;
}

@end
