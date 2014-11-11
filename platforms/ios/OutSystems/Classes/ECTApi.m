//
//  ECTApi.m
//  OutSystems
//
//  Created by engineering on 11/11/14.
//
//

#import "ECTApi.h"

@implementation ECTApi


const int kMajorVersion = 0;
const int kMinorVersion = 1;
const int kMaintenanceVersion = 2;


-(id)initWithVersion:(NSString*)version url:(NSString*)url current:(BOOL)current{
    self = [self init];
    
    self.version = version;
    self.url = url;
    self.isCurrentVersion = current;
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ApiVersion: %@, URL: %@, IsCurrentVersion: %@", self.version, self.url, self.isCurrentVersion > 0 ? @"YES" : @"NO"];
}



- (NSComparisonResult)compare:(ECTApi *)other{
    
    NSArray *selfReleases = [self.version componentsSeparatedByString:@"."];
    NSArray *otherReleases = [other.version componentsSeparatedByString:@"."];
    
    // Is Current Version
    NSComparisonResult currentVersion =  [self compareByCurrentVersion:other];
    if(currentVersion != NSOrderedSame){
        return currentVersion;
    }
    
    if ([selfReleases count] == 0 || [otherReleases count] == 0){
        return [self.version compare: other.version];
    }
    
    // Major release version
    NSComparisonResult majorRelease =  [self compareRelease:selfReleases withOther:otherReleases forVersion:kMajorVersion];
    if(majorRelease != NSOrderedSame){
        return currentVersion;
    }
    
    
    // Minor Release version
    NSComparisonResult minorRelease =  [self compareRelease:selfReleases withOther:otherReleases forVersion:kMinorVersion];
    if(minorRelease != NSOrderedSame){
        return currentVersion;
    }
    
    
    // Maintenance release version
    NSComparisonResult maintenanceRelease =  [self compareRelease:selfReleases withOther:otherReleases forVersion:kMaintenanceVersion];
    
    if(maintenanceRelease != NSOrderedSame){
        return currentVersion;
    }
    
    
    return NSOrderedSame;
}

-(NSComparisonResult)compareByCurrentVersion:(ECTApi*)other{

    if (self.isCurrentVersion == NO && other.isCurrentVersion == YES) {
        return NSOrderedDescending;
    }
    else if (self.isCurrentVersion == YES && other.isCurrentVersion == NO) {
        return NSOrderedAscending;
    }
    
    return NSOrderedSame;
}

-(NSComparisonResult)compareRelease:(NSArray*)first withOther:(NSArray*)second  forVersion:(int)version{
    if ([first count] > version && [second count] > version ) {
        if ([first[version] intValue] < [second[version] intValue]) {
            return NSOrderedAscending;
        }
        else if ([first[version] intValue] > [second[version] intValue]) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }
    else{
        return NSOrderedSame;
    }

}

-(BOOL)isCompatibleWithVersion:(NSString*)version{
    NSArray *selfReleases = [self.version componentsSeparatedByString:@"."];
    NSArray *otherReleases = [version componentsSeparatedByString:@"."];
    
    if ([selfReleases count] != [otherReleases count] ){
        return NO;
    }
    
    BOOL majorVersion = [selfReleases[kMajorVersion] intValue] == [otherReleases[kMajorVersion] intValue];
    BOOL minorVersion = [selfReleases[kMinorVersion] intValue] == [otherReleases[kMinorVersion] intValue];
    
    // Compatible iff major release version and minor release version are the same of the two versions
    return majorVersion && minorVersion;
}

@end