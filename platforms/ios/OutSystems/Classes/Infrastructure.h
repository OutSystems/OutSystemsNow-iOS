//
//  Infrastructure.h
//  HubApp
//
//  Created by engineering on 02/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Infrastructure : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * hostname;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property BOOL isJavaServer;
@property (nonatomic, retain) NSDate * lastUsed;
@property BOOL isValid;

- (NSString *) getHostnameForService:servicename;

@end
