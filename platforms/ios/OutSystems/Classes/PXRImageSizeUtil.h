//
//  PXRImageSizeUtil.h
//  OutSystemsHub
//
//  Created by Gonçalo Borrêga on 4/26/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
	PXRImageSizeUtilVerticalAlignTop,
	PXRImageSizeUtilVerticalAlignBottom,
	PXRImageSizeUtilVerticalAlignMiddle
}PXRImageSizeUtilVerticalAlign;

typedef enum {
	PXRImageSizeUtilHorizontalAlignLeft,
	PXRImageSizeUtilHorizontalAlignRight,
	PXRImageSizeUtilHorizontalAlignCenter
}PXRImageSizeUtilHorizontalAlign;

@interface PXRImageSizeUtil : NSObject

+ (UIImage*)constrain:(UIImage*)img withSize:(CGSize)size;
+ (UIImage*)crop:(UIImage*)img withSize:(CGSize)size alignVertical:(PXRImageSizeUtilVerticalAlign)vert andHorizontal:(PXRImageSizeUtilHorizontalAlign)horiz;
+ (UIImage*)stretch:(UIImage*)img withSize:(CGSize)size;
+ (UIImage*)frame:(UIImage*)img withSize:(CGSize)size alignVertical:(PXRImageSizeUtilVerticalAlign)vert andHorizontal:(PXRImageSizeUtilHorizontalAlign)horiz bgColor:(UIColor*)color;
+ (UIImage*)rotate:(UIImage*)img inDirection:(int)direction;
+ (UIImage*)rotateAndScaleCameraImage:(UIImage*)img withSize:(CGSize)size usingType:(NSString*)type;

@end