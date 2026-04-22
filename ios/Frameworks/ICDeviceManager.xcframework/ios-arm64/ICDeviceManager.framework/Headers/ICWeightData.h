//
//  ICWeightData.h
//  ICDeviceManager
//
//  Created by Symons on 2018/8/7.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

/**
 Extended weight data. Primarily used for the additional 8-electrode fields.
 */
@interface ICWeightExtData : NSObject

/**
 Left-arm body-fat percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float left_arm;

/**
 Right-arm body-fat percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float right_arm;

/**
 Left-leg body-fat percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float left_leg;

/**
 Right-leg body-fat percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float right_leg;

/**
 Trunk body-fat percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float all_body;


/**
 Left-arm fat mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float left_arm_kg;

/**
 Right-arm fat mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float right_arm_kg;

/**
 Left-leg fat mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float left_leg_kg;

/**
 Right-leg fat mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float right_leg_kg;

/**
 Trunk fat mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float all_body_kg;

/**
 Left-arm muscle percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float left_arm_muscle;

/**
 Right-arm muscle percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float right_arm_muscle;

/**
 Left-leg muscle percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float left_leg_muscle;

/**
 Right-leg muscle percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float right_leg_muscle;

/**
 Trunk muscle percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float all_body_muscle;


/**
 Left-arm muscle mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float left_arm_muscle_kg;

/**
 Right-arm muscle mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float right_arm_muscle_kg;

/**
 Left-leg muscle mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float left_leg_muscle_kg;

/**
 Right-leg muscle mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float right_leg_muscle_kg;

/**
 Trunk muscle mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float all_body_muscle_kg;

@end

/**
 Weight data.
 */
@interface ICWeightData : NSObject
/**
 User ID. Default: 0.
 */
@property (nonatomic, assign) NSUInteger userId;
/**
 Whether the sample is stable.
 @notice When unstable, only `weight_kg` and `weight_lb` are valid. Unstable samples are for display only and should not be persisted.
 */
@property (nonatomic, assign) BOOL isStabilized;

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
 Temperature in degrees Celsius.
 */
@property (nonatomic, assign) float temperature;

/**
 Measurement timestamp (seconds).
 */
@property (nonatomic, assign) NSUInteger time;

/**
 Whether the device supports heart-rate measurement.
 */
@property (nonatomic, assign) BOOL isSupportHR;

/**
 Heart-rate value.
 */
@property (nonatomic, assign) NSUInteger hr;

/**
 Body Mass Index. Precision: 0.1.
 */
@property (nonatomic, assign) float bmi;

/**
 Body-fat percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float bodyFatPercent;

/**
 Subcutaneous-fat percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float subcutaneousFatPercent;

/**
 Visceral-fat index. Precision: 0.1.
 */
@property (nonatomic, assign) float visceralFat;

/**
 Muscle percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float musclePercent;

/**
 Basal metabolic rate (kcal).
 */
@property (nonatomic, assign) NSUInteger bmr;

/**
 Bone mass (kg). Precision: 0.1.
 */
@property (nonatomic, assign) float boneMass;

/**
 Body-water percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float moisturePercent;

/**
 Physical age.
 */
@property (nonatomic, assign) float physicalAge;

/**
 Protein percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float proteinPercent;

/**
 Skeletal-muscle percentage (%). Precision: 0.1.
 */
@property (nonatomic, assign) float smPercent;

/**
 Body score.
 */
@property (nonatomic, assign) float bodyScore;

/**
 WHR
 */
@property (nonatomic, assign) float whr;

/**
 Waist circumference.
 */
@property (nonatomic, assign) float        waist;
/**
 Chest circumference.
 */
@property (nonatomic, assign) float        chest;
/**
 Hip circumference.
 */
@property (nonatomic, assign) float        hip;
/**
 Arm circumference.
 */
@property (nonatomic, assign) float        arm;
/**
 Thigh circumference.
 */
@property (nonatomic, assign) float        thigh;
/**
 Neck circumference.
 */
@property (nonatomic, assign) float        neck;


/**
 Body type.
 */
@property (nonatomic, assign) NSUInteger bodyType;

/**
 Target weight.
 */
@property (nonatomic, assign) float         targetWeight;

/**
 Weight-control target (delta vs current weight).
 */
@property (nonatomic, assign) float         weightControl;

/**
 Body-fat-mass control target (delta).
 */
@property (nonatomic, assign) float         bfmControl;

/**
 Fat-free-mass control target (delta).
 */
@property (nonatomic, assign) float         ffmControl;

/**
 Standard weight (reference).
 */
@property (nonatomic, assign) float        weightStandard;

/**
 Standard body-fat mass (reference).
 */
@property (nonatomic, assign) float        bfmStandard;

/**
 Standard BMI (reference).
 */
@property (nonatomic, assign) float        bmiStandard;

/**
 Standard skeletal-muscle mass (reference).
 */
@property (nonatomic, assign) float        smmStandard;

/**
 Standard fat-free mass (reference).
 */
@property (nonatomic, assign) float        ffmStandard;


@property (nonatomic, assign) int            bmrStandard;       // Standard BMR (reference).

@property (nonatomic, assign) float        bfpStandard;       // Standard body-fat percentage (reference).



@property (nonatomic, assign) float      bmiMax;              // BMI reference upper bound.
@property (nonatomic, assign) float      bmiMin;              // BMI reference lower bound.
@property (nonatomic, assign) float      bfmMax;              // Body-fat-mass reference upper bound.
@property (nonatomic, assign) float      bfmMin;              // Body-fat-mass reference lower bound.
@property (nonatomic, assign) float      bfpMax;              // Body-fat-percentage reference upper bound.
@property (nonatomic, assign) float      bfpMin;              // Body-fat-percentage reference lower bound.
@property (nonatomic, assign) float      weightMax;           // Weight reference upper bound.
@property (nonatomic, assign) float      weightMin;           // Weight reference lower bound.
@property (nonatomic, assign) float      smmMax;              // Skeletal-muscle-mass reference upper bound.
@property (nonatomic, assign) float      smmMin;              // Skeletal-muscle-mass reference lower bound.
@property (nonatomic, assign) float      boneMax;             // Bone-mass reference upper bound.
@property (nonatomic, assign) float      boneMin;             // Bone-mass reference lower bound.
@property (nonatomic, assign) float      waterMassMax;        // Water-mass reference upper bound.
@property (nonatomic, assign) float      waterMassMin;        // Water-mass reference lower bound.
@property (nonatomic, assign) float      proteinMassMax;      // Protein-mass reference upper bound.
@property (nonatomic, assign) float      proteinMassMin;      // Protein-mass reference lower bound.
@property (nonatomic, assign) float      muscleMassMax;       // Muscle-mass reference upper bound.
@property (nonatomic, assign) float      muscleMassMin;       // Muscle-mass reference lower bound.
@property (nonatomic, assign) NSUInteger   bmrMax;              // BMR reference upper bound.
@property (nonatomic, assign) NSUInteger   bmrMin;              // BMR reference lower bound.

/**
 Skeletal-muscle mass index (SMI).
 */
@property (nonatomic, assign) float        smi;

/**
 Obesity degree.
 */
@property (nonatomic, assign) NSUInteger      obesityDegree;



/**
 Number of electrodes (4 or 8).
 */
@property (nonatomic, assign) NSUInteger electrode;

/**
 Whole-body impedance (ohms). 0 means impedance could not be measured.
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
 Extended weight data (the additional 8-electrode fields live here).
 */
@property (nonatomic, strong) ICWeightExtData *extData;

/**
 Data-calculation method (0: SDK, 1: device).
 */
@property (nonatomic, assign) NSUInteger data_calc_type;

/**
 Body-fat algorithm version used for this reading.
 */
@property (nonatomic, assign) ICBFAType bfa_type;

@property (nonatomic, assign) NSUInteger state;

@property (nonatomic, assign) NSUInteger impendenceType;

@property (nonatomic, assign) NSUInteger impendenceProperty;
@property (nonatomic, strong) NSArray<NSNumber *> *impendences;


/**
 Upper-limb balance evaluation.
 */
@property (nonatomic, assign)ICBodyBalanceEvaluation armBalance;
/**
 Lower-limb balance evaluation.
 */
@property (nonatomic, assign)ICBodyBalanceEvaluation legBalance;
/**
 Upper-to-lower-limb balance evaluation.
 */
@property (nonatomic, assign)ICBodyBalanceEvaluation armAndLegBalance;

/**
 * Measurement mode.
 */
@property (nonatomic, assign)ICScaleMeasureMode measureMode;

@end
