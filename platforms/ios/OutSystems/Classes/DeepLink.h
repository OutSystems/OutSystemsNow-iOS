//
//  DeepLink.h
//  OutSystems
//
//  Created by engineering on 13/10/14.
//
//

#import <Foundation/Foundation.h>


extern NSString * const kDLLoginOperation;
extern NSString * const kDLOpenUrlOperation;

extern NSString * const kDLUsernameParameter;
extern NSString * const kDLPasswordParameter;
extern NSString * const kDLUrlParameter;

enum DLOperationType{
    dlLoginOperation,
    dlOpenUrlOperation,
    dlInvalidOperation
};

@interface DeepLink : NSObject

@property (nonatomic, retain) NSString * environment;
@property (nonatomic) enum DLOperationType operation;
@property (nonatomic, retain) NSMutableDictionary * parameters;

@property BOOL isValid;

-(id) initWithEnvironment:(NSString *)environment operation:(NSString *)operation parameters:(NSString *)parameters;

-(void) addEnvironment:(NSString *)environment operation:(NSString *)operation parameters:(NSString *)parameters;

-(void) invalidate;

-(NSString*)getParameterWithKey:(NSString *)key;



@end
