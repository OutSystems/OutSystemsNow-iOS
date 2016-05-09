//
//  LoginScreenController.h
//  HubApp
//
//  Created by engineering on 01/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Infrastructure.h"
#import "DeepLinkController.h"

@interface LoginScreenController : UIViewController<UIAlertViewDelegate>

@property (strong, nonatomic) Infrastructure* infrastructure;
@property BOOL loginReadonly;
@property BOOL infrastructureReadonly;

@property (strong, nonatomic) DeepLinkController* deepLinkController;

-(void)setUserCredentials:(NSString*)user password: (NSString*)pass;

@end
