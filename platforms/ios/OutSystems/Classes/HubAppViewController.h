//
//  HubAppViewController.h
//  HubApp
//
//  Created by engineering on 01/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"
#import "DeepLinkController.h"
#import "Infrastructure.h"

@interface HubAppViewController : UIViewController <TTTAttributedLabelDelegate>

@property (strong, nonatomic) DeepLinkController* deepLinkController;

-(void)setUserCredentioals:(NSString*)user password: (NSString*)pass;
-(void)resetCredentials;
-(Infrastructure*)getInfrastructure;
-(void)validateHostname;

- (Infrastructure*) getOrCreateInfrastructure: (NSString*) hostname;

@end
