//
//  DebugOverlay.h
//  Test
//
//  Created by Yogi Patel on 7/7/15.
//  Copyright (c) 2015 Yogi Patel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MKUtils.h"

@interface DebugOverlay : NSObject <MKOverlay>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) MKMapRect boundingMapRect;

- (instancetype)initWithRegion:(MKCoordinateRegion)region;

@end
