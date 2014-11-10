//
//  MobileECT.h
//  OutSystems
//
//  Created by engineering on 30/10/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Infrastructure.h"

@interface MobileECT : NSManagedObject

@property BOOL isFirstLoad;

- (NSString *) getServiceForInfrastructure:(Infrastructure *)infrastructure andURL:(NSString*)url;

@end
