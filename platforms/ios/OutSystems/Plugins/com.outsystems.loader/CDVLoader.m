//
//  CDVLoader.m
//  OutSystems
//
//  Created by engineering on 24/04/14.
//
//

#import "CDVLoader.h"

NSString* const kCDVLoaderURLPrefixShortpathCordova = @"/cdvload/";
NSString* const kCDVLoaderURLPrefixShortpathImages = @"/img/";
NSString* const kCDVLoaderURLPrefixShortpathFonts = @"/fonts/";

NSString* const kCDVLoaderURLSufixJavaScript = @".js";
NSString* const kCDVLoaderURLSufixCSS = @".css";
NSString* const kCDVLoaderURLSufixPNG = @".png";
NSString* const kCDVLoaderURLSufixGIF = @".gif";
NSString* const kCDVLoaderURLSufixWOFF = @".woff";
NSString* const kCDVLoaderURLSufixWAV = @".wav";
NSString* const kCDVLoaderURLSufixSVG = @".svg";


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
    
    if(path != nil && ([path rangeOfString:kCDVLoaderURLPrefixShortpathCordova].location != NSNotFound  ||
                       [path rangeOfString:kCDVLoaderURLPrefixShortpathImages].location != NSNotFound ||
                       [path rangeOfString:kCDVLoaderURLPrefixShortpathFonts].location != NSNotFound ||
                       [path.lastPathComponent hasSuffix:kCDVLoaderURLSufixJavaScript] ||
                       [path.lastPathComponent hasSuffix:kCDVLoaderURLSufixCSS] ||
                       [path.lastPathComponent hasSuffix:kCDVLoaderURLSufixGIF] ||
                       [path.lastPathComponent hasSuffix:kCDVLoaderURLSufixWAV] ||
                       [path.lastPathComponent hasSuffix:kCDVLoaderURLSufixSVG] ))  {
        
        
        NSURL* url = [request URL];
        
        NSData* data =[self readFileAtURL:url];
        if (!data) {
            return false;
        }
        else{
            return true;
        }
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
    
    NSData* data =[CDVLoaderURLProtocol readFileAtURL:url];
    if (data) {
        NSURLResponse *response = nil;
        
        if([[url path] hasSuffix:kCDVLoaderURLSufixJavaScript]) {
            
            response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"text/javascript"}];
            
        } else {
            if([[url path]  hasSuffix:kCDVLoaderURLSufixCSS]) {
                response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"text/css"}];
                
            } else {
                
                if([[url path]  hasSuffix:kCDVLoaderURLSufixPNG]) {
                    response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"image/png"}];
                    
                } else {
                    if([[url path]  hasSuffix:kCDVLoaderURLSufixGIF]) {
                        response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"image/gif"}];
                        
                    } else {
                        if([[url path]  hasSuffix:kCDVLoaderURLSufixWAV]) {
                            response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"audio/wav"}];
                            
                        } else {
                            if([[url path]  hasSuffix:kCDVLoaderURLSufixSVG]) {
                                response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"img/svg"}];
                                
                            } else {
                                response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"headerFields:@{@"Content-Type": @"*/*"}];
                                
                            }
                        }
                        
                    }
                }
            }
            
        }
        
        
        
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


+ (NSData *)readFileAtURL:(NSURL *)URL
{
    NSString* path = [self filesystemPathForURL:URL];
    
    NSData* readData = [NSData dataWithContentsOfFile:path];
    
    return readData;
}


+ (NSString *)filesystemPathForURL:(NSURL *)url
{
    NSError *error = nil;
    NSString *urlString = [url path];
    
    NSRegularExpression *regex = nil;
    
    if([urlString rangeOfString:kCDVLoaderURLPrefixShortpathCordova].location != NSNotFound){
        
        regex = [NSRegularExpression regularExpressionWithPattern:@"(/([\\da-zA-Z\\.-]+))?/cdvload/" options:NSRegularExpressionCaseInsensitive error:&error];
        urlString = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length]) withTemplate:@"/www/"];
        
    }
    else {
        
        if([urlString rangeOfString:kCDVLoaderURLPrefixShortpathImages].location != NSNotFound) {
            
            regex = [NSRegularExpression regularExpressionWithPattern:@"/([\\da-zA-Z\\.-]+)/img/" options:NSRegularExpressionCaseInsensitive error:&error];
            urlString = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length]) withTemplate:@"/www/img/"];
            
        } else{
            
            if([urlString rangeOfString:kCDVLoaderURLPrefixShortpathFonts].location != NSNotFound) {
                
                regex = [NSRegularExpression regularExpressionWithPattern:@"/([\\da-zA-Z\\.-]+)/fonts/" options:NSRegularExpressionCaseInsensitive error:&error];
                urlString = [regex stringByReplacingMatchesInString:urlString options:0 range:NSMakeRange(0, [urlString length]) withTemplate:@"/www/fonts/"];
                
            } else {
                
                // Looking for specific files
                
                NSString *fileName = [url lastPathComponent];
                NSString *version = [url query];
                
                NSString *filePath = fileName;
                if([version length] > 0){
                    filePath = [NSString stringWithFormat:@"%@?%@", fileName, version];
                }
                
                if([urlString hasSuffix:kCDVLoaderURLSufixJavaScript]) {
                    
                    urlString = [NSString stringWithFormat:@"/www/js/%@",filePath ];
                    
                } else {
                    if([urlString hasSuffix:kCDVLoaderURLSufixCSS]) {
                        
                        urlString = [NSString stringWithFormat:@"/www/css/%@",filePath ];
                        
                    } else {
                        if([urlString hasSuffix:kCDVLoaderURLSufixPNG]) {
                            
                            urlString = [NSString stringWithFormat:@"/www/img/%@",filePath ];
                        }
                        else{
                            if([urlString hasSuffix:kCDVLoaderURLSufixWOFF]) {
                                
                                urlString = [NSString stringWithFormat:@"/www/fonts/%@",filePath ];
                            }
                            else{
                                if([urlString hasSuffix:kCDVLoaderURLSufixGIF]) {
                                    
                                    urlString = [NSString stringWithFormat:@"/www/img/%@",filePath ];
                                }
                                else{
                                    if([urlString hasSuffix:kCDVLoaderURLSufixWAV]) {
                                        
                                        urlString = [NSString stringWithFormat:@"/www/audio/%@",filePath ];
                                    }
                                    else{
                                        if([urlString hasSuffix:kCDVLoaderURLSufixSVG]) {
                                            
                                            urlString = [NSString stringWithFormat:@"/www/img/%@",filePath ];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
        }
        
    }
    
    
    
    urlString = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:urlString];
    
    NSString *query = [url query];
    
    if(query){
        
        if([urlString rangeOfString:@"?"].location == NSNotFound){
            urlString = [NSString stringWithFormat:@"%@?%@",urlString,query];
        }
    }
    
    return urlString;
}

@end
