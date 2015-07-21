//
//  OSNavigationController.h
//  OutSystems
//
//  Created by engineering on 04/11/14.
//
//

#ifndef OutSystems_OSNavigationController_h
#define OutSystems_OSNavigationController_h

#import <Foundation/Foundation.h>
#import "DeepLinkController.h"

@interface OSNavigationController : UINavigationController

 @property BOOL orientationLocked;
 @property BOOL autorotationEnable;
 @property UIInterfaceOrientation lockedInterfaceOrientation;

-(void)lockInterfaceToOrientation:(UIInterfaceOrientation)toOrientation;

-(void)unlockInterfaceOrientation;

-(void)lockCurrentOrientation:(BOOL)lock;

-(void)pushRootViewController:(DeepLinkController*)deepLinkController;

@end

#endif
