//
//  ICWeightHistoryData.h
//  ICDeviceManager
//
//  Created by Symons on 2019/4/22.
//  Copyright © 2019 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICWeightCenterData.h"
#import "ICWeightData.h"
#import "ICConstant.h"

/**
 Historical weight data.
 */
@interface ICWeightHistoryData : NSObject
/**
 User ID. Default: 0.
 */
@property (nonatomic, assign) NSUInteger userId;

/**
 Weight in grams.
 */
@property (nonatomic, assign) NSUInteger weight_g;

/**
 Weight in kilograms.
 */
@property (nonatomic, assign) float weight_kg;

/**
 Weight in pounds.
 */
@property (nonatomic, assign) float weight_lb;

/**
 Weight (stones component of st:lb). Use together with weight_st_lb.
 */
@property (nonatomic, assign) NSUInteger weight_st;

/**
 Weight (pounds remainder of st:lb). Use together with weight_st.
 */
@property (nonatomic, assign) float weight_st_lb;

/**
 Decimal precision for kg. e.g. weight_kg=70.12 → precision=2; weight_kg=71.5 → precision_kg=1.
 */
@property (nonatomic, assign) NSUInteger precision_kg;

/**
 Decimal precision for lb. e.g. weight_lb=70.12 → precision=2; weight_lb=71.5 → precision_lb=1.
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
 Measurement timestamp (seconds).
 */
@property (nonatomic, assign) NSUInteger time;

/**
 Heart-rate value.
 */
@property (nonatomic, assign) NSUInteger hr;

/**
 Number of electrodes (4 or 8).
 */
@property (nonatomic, assign) NSUInteger electrode;

/**
 Whole-body impedance (ohms). A value of 0 means impedance could not be measured.
 */
@property (nonatomic, assign) float imp;

/**
 Left-hand impedance (8-electrode scales only, ohms). 0 means not measured.
 */
@property (nonatomic, assign) float imp2;

/**
 Right-hand impedance (8-electrode scales only, ohms). 0 means not measured.
 */
@property (nonatomic, assign) float imp3;

/**
 Left-foot impedance (8-electrode scales only, ohms). 0 means not measured.
 */
@property (nonatomic, assign) float imp4;

/**
 Right-foot impedance (8-electrode scales only, ohms). 0 means not measured.
 */
@property (nonatomic, assign) float imp5;

/**
 Balance / centre-of-gravity data.
 */
@property (nonatomic, strong) ICWeightCenterData *centerData;

/**
 Data-calculation method (0: SDK, 1: device).
 */
@property (nonatomic, assign) NSUInteger data_calc_type;

/**
 Body-fat algorithm version used for this reading.
 */
@property (nonatomic, assign) ICBFAType bfa_type;


@property (nonatomic, assign) NSUInteger impendenceType;

@property (nonatomic, assign) NSUInteger impendenceProperty;

@property (nonatomic, strong) NSArray<NSNumber *> *impendences;

@end


