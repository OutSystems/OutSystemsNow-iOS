//
//  HubAppAppDelegate.h
//  HubApp
//
//  Created by engineering on 01/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Infrastructure.h"
#import "DeepLinkController.h"
#import <Pushwoosh/PushNotificationManager.h>

#define OutSystemsNowRequiredVersion  @"1.1"

@interface OutSystemsAppDelegate : UIResponder <UIApplicationDelegate, PushNotificationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) DeepLinkController *deepLinkController;

+ (BOOL) hasAutoLoginPerformed;
+ (void) setAutoLoginPerformed;
+ (void) unsetAutoLoginPerformed;
+ (void) setURLForPushNotificationTokenRegistration:(NSString *)registerDeviceTokenUrl;
+ (void) registerPushToken;

+ (NSString *) GetDeviceId;

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;


@end
