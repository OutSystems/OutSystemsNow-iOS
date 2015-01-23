//
//  LoginApplication.h
//  OutSystems
//
//  Created by engineering on 08/01/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Application.h"
#import "Infrastructure.h"


@interface LoginApplication : NSManagedObject

@property (nonatomic, retain) NSString * appName;
@property (nonatomic, retain) NSString * appDesc;
@property (nonatomic, retain) NSNumber * appImage;
@property (nonatomic, retain) NSString * appPath;
@property (nonatomic, retain) NSString * hostname;
@property (nonatomic, retain) NSString * username;

+ (LoginApplication *) initWithJSON:(NSDictionary *) appJsonData forInfrastructure:(Infrastructure *) infrastructure;

+ (LoginApplication *) initWithApplication:(Application *) application forInfrastructure:(Infrastructure *) infrastructure;

@end
