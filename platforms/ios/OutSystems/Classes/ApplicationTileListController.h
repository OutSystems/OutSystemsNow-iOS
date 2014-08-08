//
//  ApplicationTileListController.h
//  HubApp
//
//  Created by engineering on 07/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Infrastructure.h"

@interface ApplicationTileListController : UIViewController

@property (strong, nonatomic) Infrastructure* infrastructure;
@property (nonatomic, assign) BOOL isDemoEnvironment;
@property (nonatomic, strong) NSCache *imageCache;
@property (strong, nonatomic) NSMutableArray *applicationList;

@end
