//
//  MKUtils.h
//  Test
//
//  Created by Yogi Patel on 7/8/15.
//  Copyright (c) 2015 Yogi Patel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MKUtils : NSObject

+ (MKMapRect)MKMapRectForCoordinateRegion:(MKCoordinateRegion)region;

@end
