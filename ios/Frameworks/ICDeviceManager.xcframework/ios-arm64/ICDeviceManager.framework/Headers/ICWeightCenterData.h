//
//  ICWeightCenterData.h
//  ICDeviceManager
//
//  Created by Symons on 2018/11/5.
//  Copyright © 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Centre-of-gravity data for a weight measurement.
 */
@interface ICWeightCenterData : NSObject

/**
 Whether the sample is stable. Unstable samples are for display only and should not be persisted.
 */
@property (nonatomic, assign) BOOL isStabilized;

/**
 Measurement timestamp (seconds).
 */
@property (nonatomic, assign) NSUInteger time;

/**
 Decimal precision for kg weight. e.g. weight=70.12 → precision=2; weight=71.5 → precision_kg=1.
 */
@property (nonatomic, assign) NSUInteger precision_kg;

/**
 Decimal precision for lb weight. e.g. weight=70.12 → precision=2; weight=71.5 → precision_lb=1.
 */
@property (nonatomic, assign) NSUInteger precision_lb;

/**
 Decimal precision for st:lb weight.
 */
@property (nonatomic, assign) NSUInteger precision_st_lb;

/**
 Scale division for kg.
 */
@property (nonatomic, assign) NSUInteger kg_scale_division;

/**
 Scale division for lb.
 */
@property (nonatomic, assign) NSUInteger lb_scale_division;

/**
 Left-side weight (grams).
 */
@property (nonatomic, assign) NSUInteger left_weight_g;

/**
 Right-side weight (grams).
 */
@property (nonatomic, assign) NSUInteger right_weight_g;


/**
 Left-side weight percentage (%).
 */
@property (nonatomic, assign) float leftPercent;

/**
 Right-side weight percentage (%).
 */
@property (nonatomic, assign) float rightPercent;

/**
 Left-side weight (kg).
 */
@property (nonatomic, assign) float left_weight_kg;

/**
 Right-side weight (kg).
 */
@property (nonatomic, assign) float right_weight_kg;

/**
 Left-side weight (lb).
 */
@property (nonatomic, assign) float left_weight_lb;

/**
 Right-side weight (lb).
 */
@property (nonatomic, assign) float right_weight_lb;

/**
 Left-side weight, stones component (st:lb).
 */
@property (nonatomic, assign) NSUInteger left_weight_st;

/**
 Right-side weight, stones component (st:lb).
 */
@property (nonatomic, assign) NSUInteger right_weight_st;

/**
 Left-side weight, pounds remainder in st:lb notation.
 */
@property (nonatomic, assign) float left_weight_st_lb;

/**
 Right-side weight, pounds remainder in st:lb notation.
 */
@property (nonatomic, assign) float right_weight_st_lb;

@end

NS_ASSUME_NONNULL_END
