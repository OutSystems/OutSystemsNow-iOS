//
//  PXRImageSizeUtil.m
//  OutSystemsHub
//
//  Created by Gonçalo Borrêga on 4/26/14.
//
//

#import "PXRImageSizeUtil.h"

@implementation PXRImageSizeUtil
+ (UIImage*)constrain:(UIImage*)img withSize:(CGSize)size{
	double perX = size.width/img.size.width;
	double perY = size.height/img.size.height;
	
	double w;
	double h;
	
	if(perX > perY){
		w = img.size.width * perY;
		h = img.size.height * perY;
	}else{
		w = img.size.width * perX;
		h = img.size.height * perX;
	}
	
	UIGraphicsBeginImageContext(CGSizeMake(w, h));
	[img drawInRect:CGRectMake(0, 0, w, h)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

+ (UIImage*)crop:(UIImage*)img withSize:(CGSize)size alignVertical:(PXRImageSizeUtilVerticalAlign)vert andHorizontal:(PXRImageSizeUtilHorizontalAlign)horiz{
	double x;
	double y;
	
	double perX = size.width/img.size.width;
	double perY = size.height/img.size.height;
	
	double w;
	double h;
	
	if(perX < perY){
		w = img.size.width * perY;
		h = img.size.height * perY;
	}else{
		w = img.size.width * perX;
		h = img.size.height * perX;
	}
	
	if(horiz == PXRImageSizeUtilHorizontalAlignRight){
		x = size.width - w;
	}else if(horiz == PXRImageSizeUtilHorizontalAlignLeft){
		x = 0;
	}else{
		x = (size.width/2) - (w/2);
	}
	
	// get the x and y position of the image
	if(vert == PXRImageSizeUtilVerticalAlignBottom){
		y = size.height - h;
	}else if(vert == PXRImageSizeUtilVerticalAlignTop){
		y = 0;
	}else{
		y = (size.height/2) - (h/2);
	}
	
	UIGraphicsBeginImageContext(size);
	[img drawInRect:CGRectMake(x, y, w, h)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

+ (UIImage*)stretch:(UIImage*)img withSize:(CGSize)size{
	UIGraphicsBeginImageContext(size);
	[img drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

+ (UIImage*)frame:(UIImage*)img withSize:(CGSize)size alignVertical:(PXRImageSizeUtilVerticalAlign)vert andHorizontal:(PXRImageSizeUtilHorizontalAlign)horiz bgColor:(UIColor*)color{
	double x;
	double y;
	
	double perX = size.width/img.size.width;
	double perY = size.height/img.size.height;
	
	double w;
	double h;
	
	if(perX > perY){
		w = img.size.width * perY;
		h = img.size.height * perY;
	}else{
		w = img.size.width * perX;
		h = img.size.height * perX;
	}
	
	if(horiz == PXRImageSizeUtilHorizontalAlignRight){
		x = size.width - w;
	}else if(horiz == PXRImageSizeUtilHorizontalAlignLeft){
		x = 0;
	}else{
		x = (size.width/2) - (w/2);
	}
	
	// get the x and y position of the image
	if(vert == PXRImageSizeUtilVerticalAlignBottom){
		y = size.height - h;
	}else if(vert == PXRImageSizeUtilVerticalAlignTop){
		y = 0;
	}else{
		y = (size.height/2) - (h/2);
	}
	UIGraphicsBeginImageContext(size);
	
	// color the background
	CGRect contextRect = CGRectMake(0, 0, size.width, size.height);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextFillRect(context, contextRect);
	
	[img drawInRect:CGRectMake(x, y, w, h)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

+ (UIImage*)rotate:(UIImage*)img inDirection:(int)direction{
	// color the background
	double w;
	double h;
	
	if(direction == 90 || direction == 270){
		w = img.size.height;
		h = img.size.width;
	}else{
		w = img.size.width;
		h = img.size.height;
	}
	
	UIGraphicsBeginImageContext(CGSizeMake(w, h));
	CGContextRef context = UIGraphicsGetCurrentContext();
	double radians = 0.0174532925;
	
	if(direction == 90){
		CGContextTranslateCTM(context, img.size.height, 0);
		CGContextRotateCTM(context, 90 * radians);
	}else if (direction == 180) {
		CGContextTranslateCTM(context, img.size.width, img.size.height);
		CGContextRotateCTM(context, 180 * radians);
	}else if (direction == 270){
		CGContextTranslateCTM(context, 0, img.size.width);
		CGContextRotateCTM(context, 270 * radians);
	}
	
	[img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

+ (UIImage*)rotateAndScaleCameraImage:(UIImage*)img withSize:(CGSize)size usingType:(NSString*)type{
	int orient = [img imageOrientation];
	UIImage *newImage = nil;
	if(orient == UIImageOrientationUp){
		newImage = [self constrain:img withSize:CGSizeMake(size.height, size.width)];
		newImage = [self rotate:newImage inDirection:90];
	}else if (orient == UIImageOrientationDown){
		newImage = [self constrain:img withSize:CGSizeMake(size.height, size.width)];
		newImage = [self rotate:newImage inDirection:270];
	}else if(orient == UIImageOrientationLeft){
		newImage = [self constrain:img withSize:size];
	}else if (orient == UIImageOrientationRight){
		newImage = [self constrain:img withSize:size];
	}
	return newImage;
}
@end
