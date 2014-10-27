//
//  CDVLoader.m
//  OutSystems
//
//  Created by engineering on 24/04/14.
//
//

#import "CDVLoader.h"

NSString* const kCDVLoaderURLPrefix = @"/cdvload/";

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
    NSURL* url = [request URL];
    
    BOOL canInit;
    
    canInit = [[url path] hasPrefix:kCDVLoaderURLPrefix];
    
    return canInit;
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
    NSString* path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[url path]];
    path = [path stringByReplacingOccurrencesOfString:kCDVLoaderURLPrefix withString:@"/www/"];
    return path;
}


@end
