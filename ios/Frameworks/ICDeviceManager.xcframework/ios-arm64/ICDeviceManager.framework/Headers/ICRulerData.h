//
//  ICRulerData.h
//  ICDeviceManager
//
//  Created by Symons on 2018/8/9.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

/**
 Tape-measure data.
 */
@interface ICRulerData : NSObject

/**
 Whether the sample is stable.
 @notice When unstable, only `distance` is valid; unstable samples are for display only and should not be persisted.
 */
@property (nonatomic, assign) BOOL isStabilized;

/**
 Distance (inches).
 */
@property (nonatomic, assign) float distance_in;

/**
 Distance (centimetres).
 */
@property (nonatomic, assign) float distance_cm;


/**
 Distance (feet).
 */
@property (nonatomic, assign) NSUInteger distance_ft;

/**
 Distance (feet+inches combined).
 */
@property (nonatomic, assign) float distance_ft_in;


/**
 Measured length in 0.1mm units.
 */
@property (nonatomic, assign) NSUInteger distance;

/**
 Measurement timestamp (seconds).
 */
@property (nonatomic, assign) NSUInteger time;

/**
 Body-part type being measured.
 */
@property (nonatomic, assign) ICRulerBodyPartsType partsType;

/**
 Decimal precision for inch distance. e.g. distance_in=70.12 → precision_in=2; distance_in=71.5 → precision_in=1.
 */
@property (nonatomic, assign) NSUInteger precision_in;

/**
 Decimal precision for centimetre distance. e.g. distance_cm=70.12 → precision_cm=2; distance_cm=71.5 → precision_cm=1.
 */
@property (nonatomic, assign) NSUInteger precision_cm;

/**
 Unit used for this measurement.
 */
@property (nonatomic, assign) ICRulerUnit unit;

/**
 Measurement mode used for this measurement.
 */
@property (nonatomic, assign) ICRulerMeasureMode mode;

@end
