//
//  OSNavigationBarAlert.h
//  OutSystems
//
//  Created by engineering on 09/02/15.
//
//

#import <UIKit/UIKit.h>

@interface OSNavigationBarAlert : UIView

@property (strong, nonatomic) NSString *messageText;


-(void)createView;
-(void)showAlert:(NSString*)message animated:(BOOL)animated;
-(void)hideAlert:(BOOL)animated;

-(void)navigationBarHeightChange:(float)height;

@end
