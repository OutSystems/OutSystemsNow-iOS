//
//  Infrastructure.m
//  HubApp
//
//  Created by engineering on 02/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import "Infrastructure.h"


@implementation Infrastructure

@dynamic name;
@dynamic hostname;
@dynamic username;
@dynamic password;
@dynamic lastUsed;
@dynamic isJavaServer;

- (NSString *) getHostnameForService:(NSString *)servicename {
    NSString *service;
    
    if(self.isJavaServer) {
        service = [NSString stringWithFormat:@"https://%@/OutSystemsNowService/%@.jsf", self.hostname, servicename];
    } else {
        service = [NSString stringWithFormat:@"https://%@/OutSystemsNowService/%@.aspx", self.hostname, servicename];
    }
    
    return service;
}

@end
