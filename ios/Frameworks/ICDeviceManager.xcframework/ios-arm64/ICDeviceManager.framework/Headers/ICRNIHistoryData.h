//
//  ICRNIHistoryData.h
//  ICDeviceManager
//
//  Created by icomon on 2025/1/20.
//  Copyright © 2025 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICRNIData.h"

NS_ASSUME_NONNULL_BEGIN
/**
 RNI (Recommended Nutrient Intake) history data.
 */
@interface ICRNIHistoryData : NSObject

/**
 Month.
 */
@property (nonatomic, assign) NSUInteger month;
/**
 Day.
 */
@property (nonatomic, assign) NSUInteger day;

/**
 List of nutrient-intake entries.
 */
@property (nonatomic, strong) NSArray<ICRNIData *> *rnis;

@end

NS_ASSUME_NONNULL_END
