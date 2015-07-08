//
//  DebugOverlay.m
//  Test
//
//  Created by Yogi Patel on 7/7/15.
//  Copyright (c) 2015 Yogi Patel. All rights reserved.
//

#import "DebugOverlay.h"

@implementation DebugOverlay

- (instancetype)initWithRegion:(MKCoordinateRegion)region {
    self = [super init];
    if (self) {
        _coordinate = region.center;
        _boundingMapRect = [MKUtils MKMapRectForCoordinateRegion:region];
    }
    return self;
}

@end
