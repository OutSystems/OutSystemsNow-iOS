//
//  OSNavigationController.m
//  OutSystems
//
//  Created by engineering on 04/11/14.
//
//

#import "OSNavigationController.h"
#import "ApplicationSettingsController.h"

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
    else{
        switch (self.lockedInterfaceOrientation) {
            case UIInterfaceOrientationPortrait:
                return UIInterfaceOrientationMaskPortrait;
            case UIInterfaceOrientationPortraitUpsideDown:
                return UIInterfaceOrientationMaskPortraitUpsideDown;
            case UIInterfaceOrientationLandscapeLeft:
                return UIInterfaceOrientationMaskLandscapeLeft;
            case UIInterfaceOrientationLandscapeRight:
                return UIInterfaceOrientationMaskLandscapeRight;
            case UIInterfaceOrientationUnknown:
                return UIInterfaceOrientationMaskAll;
            default:
                return self.lockedInterfaceOrientation;
        }
    }

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    if(self.autorotationEnable)
        return YES;
    else{
        return (toInterfaceOrientation == self.lockedInterfaceOrientation);
    }
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
    self.orientationLocked = NO;
}

-(void)lockCurrentOrientation:(BOOL)lock{
    NSLog(@"Lock Interface to Current Orientation: %d",lock);
    self.orientationLocked = lock;
}



# pragma mark - Navigation
-(void)pushRootViewController:(DeepLinkController*)deepLinkController{
    
    UIStoryboard *storyboard = self.storyboard;
    
    UIViewController *rootViewControler = [ApplicationSettingsController rootViewController:storyboard deepLinkController:deepLinkController];
    
    [self pushViewController:rootViewControler animated:NO];
    
}


@end