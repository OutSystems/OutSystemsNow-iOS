//
//  CanvasView.h
//  OutSystems
//
//  Created by engineering on 05/11/14.
//
//

#ifndef OutSystems_CanvasView_h
#define OutSystems_CanvasView_h

#import <UIKit/UIKit.h>

@interface CanvasView : UIView


-(void)setBackgroundImage:(UIImage*)bgImage;

-(UIImage*)getCanvasImage;

-(void)clearCanvas;

@end

#endif
