//
//  ECTApi.h
//  OutSystems
//
//  Created by engineering on 11/11/14.
//
//

#ifndef OutSystems_ECTApi_h
#define OutSystems_ECTApi_h

#import <Foundation/Foundation.h>

@interface ECTApi : NSObject

@property(nonatomic, retain)  NSString* version;
@property (nonatomic) BOOL isCurrentVersion;
@property (nonatomic, retain) NSString* url;


-(id)initWithVersion:(NSString*)version url:(NSString*)url current:(BOOL)current;

- (NSComparisonResult)compare:(ECTApi *)other;

-(BOOL)isCompatibleWithVersion:(NSString*)version;

@end

#endif
