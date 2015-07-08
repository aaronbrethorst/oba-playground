//
//  ViewController.m
//  Test
//
//  Created by Yogi Patel on 7/7/15.
//  Copyright (c) 2015 Yogi Patel. All rights reserved.
//

#import "ViewController.h"
#import "TileLoader.h"
#import "DebugOverlay.h"
#import "StopAnnotation.h"
#import <MapKit/MapKit.h>
#import <INTULocationManager.h>

@interface ViewController () <MKMapViewDelegate>
@property TileLoader *tileLoader;
@property IBOutlet MKMapView *mapView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tileLoader = [TileLoader new];
    self.tileLoader.mapView = self.mapView;
    [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyRoom
                                                                     timeout:1
                                                        delayUntilAuthorized:YES
                                                                       block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                                                           self.mapView.userTrackingMode = MKUserTrackingModeFollow;
                                                                       }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self.tileLoader loadInRegion:mapView.region
                         complete:^(NSArray *things) {
                             [mapView addAnnotations:things];
                         }];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    [views setValue:@0 forKey:@"alpha"];
    [views setValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(0, 0)] forKey:@"transform"];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.75];
    [views setValue:@1 forKey:@"alpha"];
    [views setValue:[NSValue valueWithCGAffineTransform:CGAffineTransformIdentity] forKey:@"transform"];
    [UIView commitAnimations];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *const stopAnnotationViewReuseID = @"stopAnnotationView";
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKAnnotationView *view = [self.mapView dequeueReusableAnnotationViewWithIdentifier:stopAnnotationViewReuseID];
    if (!view) {
        view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:stopAnnotationViewReuseID];
        view.canShowCallout = YES;
        view.image = [UIImage imageNamed:@"reddot"];
    }
    
    return view;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(DebugOverlay*)overlay {
    MKMapRect rect = overlay.boundingMapRect;
    MKMapPoint points[4] = {
                            {MKMapRectGetMinX(rect), MKMapRectGetMinY(rect)},
                            {MKMapRectGetMinX(rect), MKMapRectGetMaxY(rect)},
                            {MKMapRectGetMaxX(rect), MKMapRectGetMaxY(rect)},
                            {MKMapRectGetMaxX(rect), MKMapRectGetMinY(rect)}
    };
    MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:[MKPolygon polygonWithPoints:points count:4]];
    renderer.strokeColor = [UIColor blueColor];
    renderer.lineWidth = 1.0f;
    
    return renderer;
}

@end
