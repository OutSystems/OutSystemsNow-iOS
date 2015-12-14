//
//  CDVLoader.m
//  OutSystems
//
//  Created by engineering on 24/04/14.
//
//

#import "CDVLoader.h"

NSString* const kCDVLoaderURLPrefix = @"/Native/cdvload/";
NSString* const kCDVLoaderURLPrefixShortpath = @"/cdvload/";

@implementation CDVLoader


- (id)initWithWebView:(UIWebView*)theWebView
{
    self = (CDVLoader*)[super initWithWebView:theWebView];
    if (self) {
        [NSURLProtocol registerClass:[CDVLoaderURLProtocol class]];
    }
    
    return self;
}


@end


@implementation CDVLoaderURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request
{
    NSString *path = [[request URL] path];
    
    if(path != nil && [path rangeOfString:kCDVLoaderURLPrefixShortpath].location != NSNotFound) {
        return true;
    }
    else {
        return false;
    }
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest*)requestA toRequest:(NSURLRequest*)requestB
{
    return [[[requestA URL] resourceSpecifier] isEqualToString:[[requestB URL] resourceSpecifier]];
}

- (void)startLoading
{
    NSURL* url = [[self request] URL];
    
    NSData* data =[self readFileAtURL:url];
    if (data) {
        NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"*/*"}];
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    } else {
        NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404 HTTPVersion:@"HTTP/1.1"headerFields:@{}];
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocolDidFinishLoading:self];
    }
}

- (void)stopLoading
{
    // do any cleanup here
}


- (NSData *)readFileAtURL:(NSURL *)URL
{
    NSString* path = [self filesystemPathForURL:URL];
    
    NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:path];
    
    NSData* readData;

    readData = [file readDataToEndOfFile];
    [file closeFile];
    
    return readData;
}


- (NSString *)filesystemPathForURL:(NSURL *)url
{
    NSError *error = nil;
    NSString *urlString = [url path];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(/([\\da-zA-Z\\.-]+))?/cdvload/" options:NSRegularExpressionCaseInsensitive error:&error];
    
    urlString = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length]) withTemplate:@"/www/"];
    
    urlString = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:urlString];
    
    return urlString;
}



@end
