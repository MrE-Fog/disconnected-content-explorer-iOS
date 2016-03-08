//
//  GeoPackageURLProtocol.m
//  DICE
//
//  Created by Brian Osborn on 3/7/16.
//  Copyright © 2016 mil.nga. All rights reserved.
//

#import "GeoPackageURLProtocol.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageCache.h"
#import "GPKGIOUtils.h"
#import "GPKGGeoPackageValidate.h"
#import "GPKGOverlayFactory.h"
#import "URLProtocolUtils.h"

@interface GeoPackageURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSArray<NSString *> * tables;
@property (nonatomic) int zoom;
@property (nonatomic) int x;
@property (nonatomic) int y;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation GeoPackageURLProtocol

static NSString *urlProtocolHandledKey = @"GeoPackageURLProtocolHandledKey";

+ (void)start
{
    [NSURLProtocol registerClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    BOOL supports = NO;
    
    if(request != nil  && ![NSURLProtocol propertyForKey:urlProtocolHandledKey inRequest:request]){
        NSURL * url = [request URL];
        if(url != nil && [url isFileURL]){
            supports = [GPKGGeoPackageValidate hasGeoPackageExtension:url.path];
        }
    }
    
    return supports;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}


- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client {
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self != nil) {
        NSURL * url = [request URL];
        
        self.path = url.path;
        
        NSDictionary<NSString *, NSArray *> * query = [URLProtocolUtils parseQueryFromUrl:url];
        self.tables = [query valueForKey:@"table"];
        self.zoom = [[[query valueForKey:@"z"] objectAtIndex:0] intValue];
        self.x = [[[query valueForKey:@"x"] objectAtIndex:0] intValue];
        self.y = [[[query valueForKey:@"y"] objectAtIndex:0] intValue];

    }
    return self;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:urlProtocolHandledKey inRequest:newRequest];
    
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
    
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
    GPKGGeoPackageCache *cache = [[GPKGGeoPackageCache alloc]initWithManager:manager];
    
    NSString * name = [[self.path lastPathComponent] stringByDeletingPathExtension];
    
    if(![manager exists:name]){
        [manager importGeoPackageFromPath:self.path withName:name];
    }
    GPKGGeoPackage * geoPackage = [cache getOrOpen:name];
    
    NSData *tileData = nil;
    
    for(NSString * table in self.tables){
        
        GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:table];
    
        GPKGBoundedOverlay * boundedOverlay = [GPKGOverlayFactory getBoundedOverlay:tileDao];
        if([boundedOverlay hasTileWithX:self.x andY:self.y andZoom:self.zoom]){
            tileData = [boundedOverlay retrieveTileWithX:self.x andY:self.y andZoom:self.zoom];
        }
     
        if(tileData != nil){
            break;
        }
    }
    
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                        MIMEType:nil
                                           expectedContentLength:tileData.length
                                                textEncodingName:nil];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:tileData];
    [self.client URLProtocolDidFinishLoading:self];
    
}

- (void)stopLoading {
    [self.connection cancel];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
