//
//  DemoInfrastructure.m
//  OutSystems
//
//  Created by engineering on 14/04/14.
//
//

#import "DemoInfrastructure.h"

@implementation DemoInfrastructure

+ (NSString *) getHostnameForService:(NSString *)servicename; {
    NSString *service;
    
    service = [NSString stringWithFormat:@"https://%@/OutSystemsNowService/%@.aspx", self.hostname, servicename];
    
    return service;
}

+ (NSString *) hostname {
    return @"apps.outsystems.com";
}

@end
