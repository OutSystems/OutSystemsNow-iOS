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
        self.autorotationEnable = YES;
        self.lockedInterfaceOrientation = UIInterfaceOrientationMaskAll;
    }
    return self;
}

-(BOOL) shouldAutorotate {
    return self.autorotationEnable;
}


-(NSUInteger)supportedInterfaceOrientations
{
    if(self.autorotationEnable)
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
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
    self.autorotationEnable = NO;
    self.lockedInterfaceOrientation = toOrientation;
}

-(void)unlockInterfaceOrientation{
    self.autorotationEnable = YES;
    self.lockedInterfaceOrientation = UIInterfaceOrientationMaskAll;
}

@end