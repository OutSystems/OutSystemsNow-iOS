//
//  NoAnimationSegue.m
//  OutSystems
//
//  Created by engineering on 30/05/14.
//
//

#import "NoAnimationSegue.h"

@implementation NoAnimationSegue

-(void) perform {
    UIViewController *source = self.sourceViewController;
    UIViewController *destination = self.destinationViewController;
    
    // perform animation here
    [source.navigationController pushViewController:destination animated:NO];
}

@end
