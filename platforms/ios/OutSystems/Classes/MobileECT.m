//
//  MobileECT.m
//  OutSystems
//
//  Created by engineering on 30/10/14.
//
//

#import "MobileECT.h"

@implementation MobileECT

@dynamic isFirstLoad;

-(id)init{
    self = [super init];
    
    self.isFirstLoad = YES;
    
    return self;
}

- (NSString *) getServiceForInfrastructure:(Infrastructure *)infrastructure{
    if(!infrastructure)
        return nil;
    
    NSString *service;
    
    if(infrastructure.isJavaServer) {
        service = [NSString stringWithFormat:@"https://%@/MobileECT/submitFeedback.jsf", infrastructure.hostname];
    } else {
        service = [NSString stringWithFormat:@"https://%@/MobileECT/submitFeedback.aspx", infrastructure.hostname];
    }
    
    return service;
}

@end
