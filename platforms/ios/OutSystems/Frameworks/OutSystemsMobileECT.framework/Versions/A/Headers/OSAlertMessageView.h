//
//  OSAlertMessageView.h
//  OutSystemsMobileECTStaticLib
//
//  Created by engineering on 04/12/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#ifndef OutSystemsMobileECTStaticLib_OSAlertMessageView_h
#define OutSystemsMobileECTStaticLib_OSAlertMessageView_h

#import <Foundation/Foundation.h>
#import "OSAlertView.h"

@interface OSAlertMessageView : OSAlertView


-(id)initWithParent:(id)parent withTitle:(NSString*)title withMessage:(NSString*)message andSelector:(SEL)selector;


@end

#endif
