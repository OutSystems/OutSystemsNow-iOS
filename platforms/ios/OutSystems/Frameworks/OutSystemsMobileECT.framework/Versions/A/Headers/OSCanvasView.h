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

@interface OSCanvasView : UIView


-(void)setBackgroundImage:(UIImage*)bgImage;

-(UIImage*)getCanvasImage;

-(void)clearCanvas;

-(void)addOnDrawingTarget:(id)target beginSelector:(SEL)beginSelector updateSelector:(SEL)updateSelector endSelector:(SEL)endSelector;

-(void)lockCanvas:(BOOL) lock;

@end

#endif
