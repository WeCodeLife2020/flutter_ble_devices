//
//  ICUserInfo.h
//  ICleDevice
//
//  Created by lifesense-mac on 17/4/18.
//  Copyright (c) 2017 lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

@class ICRNIData;

/**
 User information.
 */
@interface ICUserInfo : NSObject

/**
 User index. Default: 1.
 */
@property (nonatomic, assign) NSUInteger userIndex;

/**
 User ID. Default: 0.
 */
@property (nonatomic, assign) NSUInteger userId;


/**
 User nickname. Default: "icomon".
 */
@property (nonatomic, strong) NSString *nickName;
/**
 Nickname checksum. Default: 0.
 */
@property (nonatomic, assign) NSUInteger nickNameCS;
/**
 Avatar sequence.
 */
@property (nonatomic, assign) NSUInteger headTypeSequence;

/**
 Avatar index.
 */
@property (nonatomic, assign) NSUInteger headType;


/**
 Language. Default: 1.
 */
@property (nonatomic, assign) NSUInteger lang;

/**
 Node ID (sports-edition devices only).
 */
@property (nonatomic, assign) NSUInteger nodeId;


/**
 Grade (sports-edition avatar).
 */
@property (nonatomic, assign) NSUInteger sclass;

/**
 Class (sports-edition devices only).
 */
@property (nonatomic, assign) NSUInteger grade;

/**
 Student number (sports-edition devices only).
 */
@property (nonatomic, assign) NSUInteger studentNo;

/**
 Height in centimetres. Default: 172.
 */
@property (nonatomic, assign) NSUInteger height;

/**
 Weight in kilograms. Default: 60.0.
 */
@property (nonatomic, assign) float weight;

/**
 Age. Default: 24.
 */
@property (nonatomic, assign) NSUInteger age;

/**
 Sex. Default: ICSexTypeMale.
 */
@property (nonatomic, assign) ICSexType sex;

/**
 Impedance from the previous measurement.
 */
@property (nonatomic, assign) float lastImpedance;
/**
 Goal type. 1: weight, 2: BMI, 3: body-fat percentage.
 */
@property (nonatomic, assign) int targetType;

/**
 Starting weight in kilograms. Default: 50.0.
 */
@property (nonatomic, assign) float startWeight;
/**
 Target weight in kilograms. Default: 50.0.
 */
@property (nonatomic, assign) float targetWeight;

/**
 Weight-goal direction. Default: 0 (lose weight). 1: gain weight.
 */
@property (nonatomic, assign) NSUInteger weightDirection;

/**
 Body-fat algorithm version to use. Default: ICBFATypeWLA01.
 */
@property (nonatomic, assign) ICBFAType bfaType;


/**
 Locked body-fat algorithm version. Once set, any algorithm version uploaded by the device is ignored. Default: ICBFATypeWLA01.
 */
@property (nonatomic, assign) ICBFAType lockBfaType;

/**
 User type. Default: ICPeopleTypeNormal.
 */
@property (nonatomic, assign) ICPeopleType peopleType;

/**
 User's default weight unit. Default: ICWeightUnitKg.
 */
@property (nonatomic, assign) ICWeightUnit weightUnit;

/**
 User's default tape-measure unit. Default: ICRulerUnitCM.
 */
@property (nonatomic, assign) ICRulerUnit rulerUnit;

/**
 User's default tape-measure mode. Default: ICRulerMeasureModeLength.
 */
@property (nonatomic, assign) ICRulerMeasureMode rulerMode;

/**
 Kitchen-scale default unit. Default: ICKitchenScaleUnitG.
 */
@property (nonatomic, assign) ICKitchenScaleUnit kitchenUnit;

/**
 BMI standard. Default: ICBMIStandard1.
 */
@property (nonatomic, assign) ICBMIStandard stanard;

/**
 * Whether impedance measurement is enabled. Default: YES. Only effective on supported devices.
 */
@property (nonatomic, assign)  BOOL enableMeasureImpendence;
/**
 * Whether heart-rate measurement is enabled. Default: YES. Only effective on supported devices.
 */
@property (nonatomic, assign)  BOOL enableMeasureHr;
/**
 * Whether balance measurement is enabled. Default: YES. Only effective on supported devices.
 */
@property (nonatomic, assign)  BOOL enableMeasureBalance;
/**
 * Whether centre-of-gravity measurement is enabled. Default: YES. Only effective on supported devices.
 */
@property (nonatomic, assign)  BOOL enableMeasureGravity;
/**
 * Whether small-object mode is enabled. Default: YES. Only effective on supported devices.
 */
@property (nonatomic, assign)  BOOL enableSmallThing;
/**
 * Whether baby mode is enabled. Default: NO. Only effective on supported devices.
 */
@property (nonatomic, assign)  BOOL enableBabyMode;

/**
 * Whether girth calculation is enabled. Unsupported by the 37 algorithm family; default off there.
 */
@property (nonatomic, assign)  BOOL enableGirth;

/**
 Nutrition-intake list.
 */
@property (nonatomic, strong) NSArray<ICRNIData *> *rniList;


@end
