//
//  ICNutritionFact.h
//  ICDeviceManager
//
//  Created by icomon on 2025/1/20.
//  Copyright © 2025 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 Nutrition fact entry.
 */
@interface ICNutritionFact : NSObject

///**
// Food ID. Set to 0 when not required.
// */
//@property (nonatomic, assign) NSUInteger foodId;
/**
 Nutrition data type.
 */
@property (nonatomic, assign) NSUInteger type;
/**
 Nutrition value.
 */
@property (nonatomic, assign) float value;


+ (instancetype)create:(NSUInteger)type value:(float)value;

@end

NS_ASSUME_NONNULL_END
