//
//  OSProgressBar.h
//  OutSystems
//
//  Created by engineering on 11/05/15.
//
//

#import <UIKit/UIKit.h>

@interface OSProgressBar : UIView

-(id)initForView:(UIView*)view;

-(void)startProgress:(BOOL)animated;
-(void)cancelProgress:(BOOL)animated;
-(void)stopProgress:(BOOL)animated;

@end
