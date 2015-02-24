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

@interface OSNavigationController : UINavigationController

 @property BOOL autorotationEnable;
 @property UIInterfaceOrientation lockedInterfaceOrientation;

-(void)lockInterfaceToOrientation:(UIInterfaceOrientation)toOrientation;

-(void)unlockInterfaceOrientation;

@end

#endif
