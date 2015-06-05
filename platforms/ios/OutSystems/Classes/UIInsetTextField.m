//
//  UIInsetTextField.m
//  HubApp
//
//  Created by engineering on 07/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import "UIInsetTextField.h"

@implementation UIInsetTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    return UIEdgeInsetsInsetRect(bounds, contentInsets);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    return UIEdgeInsetsInsetRect(bounds, contentInsets);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
