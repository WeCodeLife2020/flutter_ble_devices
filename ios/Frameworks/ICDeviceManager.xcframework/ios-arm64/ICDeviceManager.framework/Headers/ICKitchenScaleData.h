//
//  ICKitchenScaleData.h
//  ICDeviceManager
//
//  Created by Symons on 2018/8/20.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

/**
 Kitchen-scale measurement data.
 */
@interface ICKitchenScaleData : NSObject

/**
 Whether the reading is stable. Unstable readings are for display only and should not be persisted.
 */
@property (nonatomic, assign) BOOL isStabilized;

/**
 Value in milligrams.
 */
@property (nonatomic, assign) NSUInteger value_mg;

/**
 Value in grams.
 */
@property (nonatomic, assign) float value_g;

/**
 Value in millilitres (water).
 */
@property (nonatomic, assign) float value_ml;

/**
 Value in millilitres of milk.
 */
@property (nonatomic, assign) float value_ml_milk;

/**
 Value in ounces.
 */
@property (nonatomic, assign) float value_oz;

/**
 Value (pounds component of lb:oz).
 */
@property (nonatomic, assign) NSUInteger value_lb;

/**
 Value (ounces component of lb:oz).
 */
@property (nonatomic, assign) float value_lb_oz;

/**
 Value in fluid ounces.
 */
@property (nonatomic, assign) float value_fl_oz;

/**
 Value in UK fluid ounces.
 */
@property (nonatomic, assign) float value_fl_oz_uk;

/**
 Value in US fluid ounces (milk).
 */
@property (nonatomic, assign) float value_fl_oz_milk;

/**
 Value in UK fluid ounces (milk).
 */
@property (nonatomic, assign)  float value_fl_oz_milk_uk;
/**
 Measurement timestamp (seconds).
 */
@property (nonatomic, assign) NSUInteger time;

/**
 User ID.
 */
@property (nonatomic, assign) NSUInteger userId;

/**
 Food ID.
 */
@property (nonatomic, assign) NSUInteger foodId;

/**
 Unit used for this reading.
 */
@property (nonatomic, assign) ICKitchenScaleUnit unit;

/**
 Decimal precision. e.g. value_g=70.12 → precision=2; value_g=71.5 → precision=1.
 */
@property (nonatomic, assign) NSUInteger precision;
/**
 Decimal precision for grams.
 */
@property (nonatomic, assign) NSUInteger precision_g ;
/**
 Decimal precision for millilitres.
 */
@property (nonatomic, assign) NSUInteger precision_ml ;
/**
 Decimal precision for lb:oz.
 */
@property (nonatomic, assign) NSUInteger precision_lboz ;
/**
 Decimal precision for ounces.
 */
@property (nonatomic, assign) NSUInteger precision_oz ;
/**
 Decimal precision for millilitres of milk.
 */
@property (nonatomic, assign) NSUInteger precision_ml_milk ;
/**
 Decimal precision for US fluid ounces.
 */
@property (nonatomic, assign) NSUInteger precision_floz_us ;
/**
 Decimal precision for UK fluid ounces.
 */
@property (nonatomic, assign) NSUInteger precision_floz_uk ;
/**
 Decimal precision for US fluid ounces of milk.
 */
@property (nonatomic, assign) NSUInteger precision_floz_milk_us ;
/**
 Decimal precision for UK fluid ounces of milk.
 */
@property (nonatomic, assign) NSUInteger precision_floz_milk_uk ;

/**
 Device unit system. 0: metric, 1: US, 2: UK.
 */
@property (nonatomic, assign) NSUInteger unitType;


/**
 Whether the value is negative.
 */
@property (nonatomic, assign) BOOL isNegative;

/**
 Whether the tare mode is active.
 */
@property (nonatomic, assign) BOOL isTare;



/**
 * Whether the reading was confirmed by a button press.
 */
@property (nonatomic, assign) BOOL isConfirm;


@end
