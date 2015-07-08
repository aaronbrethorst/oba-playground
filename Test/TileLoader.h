//
//  TileLoader.h
//  Test
//
//  Created by Yogi Patel on 7/7/15.
//  Copyright (c) 2015 Yogi Patel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TileLoader : NSObject

@property MKMapView *mapView;

- (void)loadInRegion:(MKCoordinateRegion)region complete:(void (^)(NSArray *things))block;

@end
