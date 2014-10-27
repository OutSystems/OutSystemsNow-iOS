//
//  DeepLinkController.h
//  OutSystems
//
//  Created by engineering on 14/10/14.
//
//

#ifndef OutSystems_DeepLinkController_h
#define OutSystems_DeepLinkController_h

#import <Foundation/Foundation.h>
#import "DeepLink.h"
#import "Application.h"

@interface DeepLinkController : NSObject 

@property (strong, nonatomic) DeepLink* deepLinkSettings;
@property (strong, nonatomic) Application* destinationApp;

-(void)createSettingsFromURL:(NSURL *)url;

-(BOOL)hasValidSettings;
-(BOOL)hasCredentials;
-(BOOL)hasApplication;

-(DeepLink*)getSettings;

-(void)resolveOperation:(UIViewController*)source; 

@end

#endif
