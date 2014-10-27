//
//  ApplicationTileCell.h
//  HubApp
//
//  Created by engineering on 07/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ApplicationTileCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *applicationImage;
@property (weak, nonatomic) IBOutlet UILabel *applicationName;

@property (weak, nonatomic) IBOutlet UILabel *applicationDescription;

@end
