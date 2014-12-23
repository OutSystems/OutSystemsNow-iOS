//
//  DeepLink.m
//  OutSystems
//
//  Created by engineering on 13/10/14.
//
//

#import "DeepLink.h"

@implementation DeepLink

NSString * const kDLLoginOperation = @"login";
NSString * const kDLOpenUrlOperation = @"openurl";

NSString * const kDLUsernameParameter = @"username";
NSString * const kDLPasswordParameter = @"password";
NSString * const kDLUrlParameter = @"url";

- (id)init {
    self = [super init];
    
    if (!self.parameters) {
        self.parameters = [NSMutableDictionary new];
    }
    
    return self;
}


-(id) initWithEnvironment:(NSString *)environment operation:(NSString *)operation parameters:(NSString *)parameters{
    
    self = [self init];
    
    [self addEnvironment:environment operation:operation parameters:parameters];
    
    return self;
    
}

-(void) setOperationType:(NSString *)operation {
    if(operation){
        NSString *tmpOperation = [operation substringFromIndex: [operation rangeOfString:@"/"].location+1];
        tmpOperation = [tmpOperation lowercaseString];
        
        if ([tmpOperation rangeOfString:kDLLoginOperation].location != NSNotFound){
            self.operation = dlLoginOperation;
            return;
        }
        
        if ([tmpOperation rangeOfString:kDLOpenUrlOperation].location != NSNotFound){
            self.operation = dlOpenUrlOperation;
            return;
        }
        
        self.operation = dlInvalidOperation;
    }
}

-(void) addEnvironment:(NSString *)environment operation:(NSString *)operation parameters:(NSString *)parameters{
    
    if(environment &&  operation){
        self.isValid = YES;
    }
    else{
        self.isValid = NO;
    }
    
    self.environment = environment;

    [self setOperationType:operation];
   
    
    NSLog(@"DeepLink - Environment: %@",self.environment);
    NSLog(@"DeepLink - Operation: %@",[self dlOperationTypeToString:self.operation]);
    
    if (!self.parameters) {
        self.parameters = [NSMutableDictionary new];
    }
    else{
        [self.parameters removeAllObjects];
    }
    
    if(parameters){
        NSArray *paramList = [parameters componentsSeparatedByString:@"&"];
    
        NSUInteger count = [paramList count];
        for (NSUInteger i = 0; i < count; i++) {
        
            NSString *parameter = [paramList objectAtIndex: i];
            [self addParameter:parameter];
        
        }
    }
}

-(void) addParameter:(NSString *)parameter
{
    if (!self.parameters) {
        self.parameters = [NSMutableDictionary new];
    }
    
    
    NSRange separator = [parameter rangeOfString:@"="];

    if( separator.location == NSNotFound)
        return;
    
    NSString *key = [parameter substringToIndex:separator.location];
    key = [key lowercaseString];
    NSString *value = [parameter substringFromIndex:separator.location+1];
    
    if ([key rangeOfString:@"password"].location != NSNotFound){
        NSLog(@"DeepLink - Parameter: %@ - ******",key); // Just to ensure that password value was passed
    }
    else{
        NSLog(@"DeepLink - Parameter: %@ - %@",key,value);
    }

    
    [self.parameters setObject:value forKey:key];
}


-(void) invalidate{
    self.isValid = NO;
    
    self.environment = nil;
    self.operation = dlInvalidOperation;
    
    [self.parameters removeAllObjects];
}

-(NSString*)getParameterWithKey:(NSString *)key{
    return [self.parameters objectForKey:key];
}

-(NSString*)dlOperationTypeToString: (enum DLOperationType)operationType{
    NSString *result = nil;
    
    switch (operationType) {
        case dlLoginOperation:
            result = kDLLoginOperation;
            break;
        case dlOpenUrlOperation:
            result = kDLOpenUrlOperation;
            break;
            
        default:
            result = @"invalid operation";
            break;
    }
    
    return result;
}

@end