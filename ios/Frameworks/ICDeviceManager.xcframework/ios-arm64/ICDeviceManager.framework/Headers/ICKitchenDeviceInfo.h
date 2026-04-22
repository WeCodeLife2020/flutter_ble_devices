//
//  ICKitchenDeviceInfo.h
//  ICDeviceManager
//
//  Created by Symons on 2020/4/29.
//  Copyright © 2020 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICKitchenDeviceInfo : ICDeviceInfo

/**
 Functions supported by the scale.
 */
@property(nonatomic, strong) NSArray<NSNumber *> *supportFuns;

/**
 Nutrition-data types the scale can display.
 */
@property(nonatomic, strong) NSArray<NSNumber *> *supportDataTypes;

/**
 Number of history entries currently stored on the scale.
 */
@property(nonatomic, assign) NSUInteger historyCount;

/**
 Image endianness.
 */
@property(nonatomic, assign) NSInteger imageEndian;

/**
 Image orientation.
 */
@property(nonatomic, assign) NSInteger imageDirection;

/**
 Image colour depth.
 */
@property(nonatomic, assign) NSInteger imageColorDepth;


/**
 Current voice-recognition switch. 0: off, 1: on.
 */
@property(nonatomic, assign) BOOL isSoundSwitch;
/**
 Food-image resolution: width.
 */
@property(nonatomic, assign) NSInteger foodImageWidth;
/**
 Food-image resolution: height.
 */
@property(nonatomic, assign) NSInteger foodImageHeight;
/**
 Food-name resolution: height.
 */
@property(nonatomic, assign) NSInteger foodNameHeight;



@end

NS_ASSUME_NONNULL_END
