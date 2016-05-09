//
//  OfflineSupportController.h
//  OutSystems
//
//  Created by engineering on 08/01/15.
//
//

#ifndef OutSystems_OfflineSupportController_h
#define OutSystems_OfflineSupportController_h

#import <Foundation/Foundation.h>
#import "Infrastructure.h"
#import "LoginScreenController.h"
#import "Application.h"

@interface OfflineSupportController : NSObject

+(void)addApplications:(NSArray *)applications forInfrastructure:(Infrastructure*)infrastructure;
+(NSArray*)getLoginApplications:(Infrastructure*)infrastructure;

+(BOOL)isNetworkAvailable:(Infrastructure*)infrastructure;
+(BOOL)isNetworkAvailable;

+(BOOL)hasValidCredentials:(Infrastructure*)infrastructure;

+(void)prepareForLogin;

+(void)checkCurrentSession:(Infrastructure*)infrastructure;

+(void)clearCacheIfNeeded;

+(void)retryWebViewAction:(UIWebView*)webView failedURL:(NSString *)url forApplication:(Application*)application andInfrastructure:(Infrastructure*)infrastructure;

+(BOOL)isNewSession;

+(void)loginIfNeeded:(Infrastructure*)infrastructure;

@end


#endif
