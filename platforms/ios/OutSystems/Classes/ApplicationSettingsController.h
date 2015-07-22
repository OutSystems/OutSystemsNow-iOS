//
//  ApplicationSettingsController.h
//  OutSystems
//
//  Created by engineering on 21/07/15.
//
//

#import <Foundation/Foundation.h>
#import "DeepLinkController.h"

@interface ApplicationSettingsController : NSObject

+(BOOL)skipNativeLogin;
+(BOOL)skipApplicationList;
+(BOOL)hideNavigationBar;

+(NSString*)defaultHostname;
+(NSString*)defaultApplicationURL;

+(UIColor*)backgroundColor;
+(UIColor*)foregroundColor;
+(UIColor*)tintColor;


+(UIViewController*)rootViewController:(UIStoryboard*)storyboard deepLinkController:(DeepLinkController*)deepLinkController;

+(UIViewController*)nextViewController:(UIViewController*)currentViewController;

@end
