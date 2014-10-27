//
//  DemoInfrastructure.h
//  OutSystems
//
//  Created by engineering on 14/04/14.
//
//

#import <Foundation/Foundation.h>

@interface DemoInfrastructure : NSObject

+ (NSString *) hostname;
+ (NSString *) getHostnameForService:(NSString *)servicename;

@end
