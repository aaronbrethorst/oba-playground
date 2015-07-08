//
//  TileLoader.m
//  Test
//
//  Created by Yogi Patel on 7/7/15.
//  Copyright (c) 2015 Yogi Patel. All rights reserved.
//

#import "TileLoader.h"
#import "StopAnnotation.h"
#import "NSValue+MKCoordinateRegion.h"
#import "DebugOverlay.h"
#import "MKUtils.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

#define kChunkSize 0.01
#define kNeighborhoodSize 5 // should be an odd number
#define DRAW_OVERLAY NO
//#define kRegionRefreshThreshold 10

@interface TileLoader ()

@property AFHTTPRequestOperationManager *manager;
@property NSMutableDictionary *tiles;
@property NSMutableArray *overlays;
@property dispatch_queue_t queue;

@end


@implementation TileLoader

- (instancetype)init {
    self = [super init];
    if (self) {
        self.manager = [AFHTTPRequestOperationManager manager];
        self.tiles = [NSMutableDictionary new];
        self.overlays = [NSMutableArray new];
        self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    }
    return self;
}

- (void)boom:(NSArray *)regions {
    for (NSValue *regionValue in regions) {
        MKCoordinateRegion region = [regionValue MKCoordinateRegionValue];
        DebugOverlay *debugOverlay = [[DebugOverlay alloc] initWithRegion:region];
        [self.mapView addOverlay:debugOverlay];
    }
}

- (void)loadInRegion:(MKCoordinateRegion)unnormalizedRegion complete:(void (^)(NSArray *))complete {
    dispatch_async(self.queue, ^{
        MKCoordinateRegion normalizedRegion = [self normalizedRegionForRegion:unnormalizedRegion];
        NSArray *regions = [self neighborhoodForRegion:normalizedRegion];
        
        for (NSValue *regionValue in regions) {
            [self loadForNormalizedRegion:[regionValue MKCoordinateRegionValue]
                                 complete:^(NSArray *things) {
                                     complete(things);
                                 }];
        }
    });
}

- (void)loadForNormalizedRegion:(MKCoordinateRegion)normalizedRegion complete:(void (^)(NSArray *))complete {
    id key = [self keyForRegion:normalizedRegion];
    //    BOOL isReload = NO;
    
    NSDate *then = self.tiles[key];
    if (then) {
        //        if ([[NSDate date] timeIntervalSinceDate:then] < kRegionRefreshThreshold) {
        return;
        //        }
        //        else {
        //            isReload = YES;
        //        }
    }
    
    if (DRAW_OVERLAY) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self boom:@[[NSValue valueWithMKCoordinateRegion:normalizedRegion]]];
        });
    }
    
    NSDictionary *parameters = @{ @"lat": @(normalizedRegion.center.latitude),
                                  @"lon": @(normalizedRegion.center.longitude),
                                  @"latSpan": @(normalizedRegion.span.latitudeDelta),
                                  @"lonSpan": @(normalizedRegion.span.longitudeDelta)};
    
    [self.manager GET:@"http://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=org.onebusaway.iphone" parameters:parameters
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  dispatch_async(self.queue, ^{
                      @synchronized(self) {
                          [self.tiles setObject:[NSDate date] forKey:[self keyForRegion:normalizedRegion]];
                      }
                      
                      NSArray *stopsInfo = responseObject[@"data"][@"list"];
                      NSMutableArray *stopAnnotations = [NSMutableArray arrayWithCapacity:stopsInfo.count];
                      
                      for (NSDictionary *info in stopsInfo) {
                          StopAnnotation *annotation = [StopAnnotation new];
                          annotation.title = info[@"name"];
                          
                          double latitude = [info[@"lat"] doubleValue];
                          double longitude = [info[@"lon"] doubleValue];
                          annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                          
                          [stopAnnotations addObject:annotation];
                      }
                      
                      dispatch_async(dispatch_get_main_queue(), ^{
                          complete([NSArray arrayWithArray:stopAnnotations]);
                      });
                      
                      
//                              if (isReload) {
//                                  NSSet *annotationsToRemove = [self.mapView annotationsInMapRect:[MKUtils MKMapRectForCoordinateRegion:normalizedRegion]];
//                                  [self.mapView removeAnnotations:[annotationsToRemove allObjects]];
//                              }

                  });
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  NSLog(@"Error: %@", error);
              }];
}

- (id)keyForRegion:(MKCoordinateRegion)region {
    return [NSString stringWithFormat:@"%d,%d", [self latitudeIndexForRegion:region], [self longitudeIndexForRegion:region]];
}

- (MKCoordinateRegion)normalizedRegionForRegion:(MKCoordinateRegion)region {
    return [self normalizedRegionForLatitudeIndex:[self latitudeIndexForRegion:region]
                                   longitudeIndex:[self longitudeIndexForRegion:region]];
}

- (MKCoordinateRegion)normalizedRegionForLatitudeIndex:(int)latitudeIndex longitudeIndex:(int)longitudeIndex {
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([self latitudeForIndex:latitudeIndex],
                                                               [self longitudeForIndex:longitudeIndex]);
    MKCoordinateSpan span = MKCoordinateSpanMake(kChunkSize, kChunkSize);
    
    return MKCoordinateRegionMake(center, span);
}

- (int)latitudeIndexForRegion:(MKCoordinateRegion)region {
    return floor((region.center.latitude + 90) / kChunkSize);
}

- (double)latitudeForIndex:(int)index {
    return (index * kChunkSize) - 90 + (kChunkSize / 2);
}

- (int)longitudeIndexForRegion:(MKCoordinateRegion)region {
    return floor((region.center.longitude + 180) / kChunkSize);
}

- (double)longitudeForIndex:(int)index {
    return (index * kChunkSize) - 180 + (kChunkSize / 2);
}

- (NSArray*)neighborhoodForRegion:(MKCoordinateRegion)region {
    int latitudeIndex = [self latitudeIndexForRegion:region];
    int longitudeIndex = [self longitudeIndexForRegion:region];
    
    NSMutableArray *regions = [[NSMutableArray alloc] initWithCapacity:8];
    
    int max = floor(kNeighborhoodSize / 2);
    int min = -max;
    
    for (int i = min; i <= max; i++) {
        for (int k = min; k <= max; k++) {
            [regions addObject:[NSValue valueWithMKCoordinateRegion:
                                [self normalizedRegionForLatitudeIndex:latitudeIndex + i
                                                        longitudeIndex:longitudeIndex + k]]];
        }
    }
    
    return [NSArray arrayWithArray:regions];
}

@end
