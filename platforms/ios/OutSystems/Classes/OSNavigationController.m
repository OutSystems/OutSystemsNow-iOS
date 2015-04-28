//
//  OSNavigationController.m
//  OutSystems
//
//  Created by engineering on 04/11/14.
//
//

#import "OSNavigationController.h"

@implementation OSNavigationController

@synthesize autorotationEnable;
@synthesize lockedInterfaceOrientation;

#pragma mark - Overriden methods

-(id)init{
    self = [super init];
    if(self){
        self.orientationLocked = NO;
        self.autorotationEnable = YES;
        self.lockedInterfaceOrientation = UIInterfaceOrientationMaskAll;
    }
    return self;
}

-(BOOL) shouldAutorotate {
    return !self.orientationLocked && self.autorotationEnable;
}


-(NSUInteger)supportedInterfaceOrientations
{
    if(self.autorotationEnable)
        return UIInterfaceOrientationMaskAll;
    else
        return self.lockedInterfaceOrientation;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if(self.autorotationEnable)
        return UIInterfaceOrientationPortrait;
    else
        return self.lockedInterfaceOrientation;
}


#pragma mark - OS Methods

-(void)lockInterfaceToOrientation:(UIInterfaceOrientation)toOrientation{
    NSLog(@"Lock Interface to Orientation: %ld",(long)toOrientation);
    self.autorotationEnable = NO;
    self.lockedInterfaceOrientation = toOrientation;
}

-(void)unlockInterfaceOrientation{
    NSLog(@"Unlock Interface Orientation");
    self.autorotationEnable = YES;
    self.lockedInterfaceOrientation = UIInterfaceOrientationMaskAll;
}

-(void)lockCurrentOrientation:(BOOL)lock{
    NSLog(@"Lock Interface to Current Orientation: %d",lock);
    self.orientationLocked = lock;
}

@end