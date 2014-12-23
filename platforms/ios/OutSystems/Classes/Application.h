//
//  Application.h
//  HubApp
//
//  Created by engineering on 03/04/14.
//  Copyright (c) 2014 OutSystems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Application : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * appDescription;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * imageId;
@property BOOL feedbackActive;

+ (Application *) initWithJSON:(NSDictionary *) appJsonData forHost:(NSString *) hostname;

@end
