//
//  ICSkipParam.h
//  ICDeviceManager
//
//  Created by symons on 2022/9/21.
//  Copyright © 2022 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICSkipParam : NSObject

/**
 Mode.
 */
@property (nonatomic, assign) ICSkipMode mode;

/**
 Skipping parameter. Interval mode: per-round duration (S2: per-round count).

 */
@property (nonatomic, assign) NSUInteger param;

/**
 Rest interval between rounds in the interval mode.
 */
@property (nonatomic, assign) NSUInteger rest_time;

/**
 Number of groups in the interval mode.
 */
@property (nonatomic, assign) NSUInteger group;


/**
 Competition mode (sports edition). 0: 5-person competition, 1: team competition.
 */
@property (nonatomic, assign) NSUInteger matchMode;


@end

NS_ASSUME_NONNULL_END
