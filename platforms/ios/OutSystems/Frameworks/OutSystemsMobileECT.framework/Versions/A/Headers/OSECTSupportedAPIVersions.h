//
//  OSECTSupportedAPIVersions.h
//  OutsystemsMobileFrameworks
//
//  Created by engineering on 12/11/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#ifndef OutsystemsMobileFrameworks_OSECTSupportedAPIVersions_h
#define OutsystemsMobileFrameworks_OSECTSupportedAPIVersions_h

#import <UIKit/UIKit.h>
#import "OSECTApi.h"

@interface OSECTSupportedAPIVersions : NSObject

@property (retain, nonatomic) NSMutableArray *supportedApiVersions;


-(id)init;

-(void)addVersion:(OSECTApi*) api;
-(void)removeAllVersions;

-(BOOL)checkCompatibilityWithVersion:(NSString *)version;
-(NSString*)getAPIVersionURL;

@end


#endif
