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

- (NSString *) getServiceForInfrastructure:(Infrastructure *)infrastructure andURL:(NSString*)url{
    if(!infrastructure)
        return nil;
    
    NSString *service = [NSString stringWithFormat:@"https://%@%@", infrastructure.hostname,url];
    
    return service;
}

@end
