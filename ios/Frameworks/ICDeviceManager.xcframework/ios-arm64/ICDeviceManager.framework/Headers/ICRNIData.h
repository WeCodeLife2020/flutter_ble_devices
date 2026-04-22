//
//  ICRNIData.h
//  ICDeviceManager
//
//  Created by icomon on 2025/1/20.
//  Copyright © 2025 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 RNI (Recommended Nutrient Intake) data.
 */
@interface ICRNIData : NSObject

/**
 Data type.
 */
@property (nonatomic, assign) NSUInteger type;

/**
 Current intake amount.
 */
@property (nonatomic, assign) float current;

/**
 Maximum or target intake amount.
 */
@property (nonatomic, assign) float max;

/**
 Progress percentage in the range 0-100%.
 */
@property (nonatomic, assign) float progress;

@end

NS_ASSUME_NONNULL_END
