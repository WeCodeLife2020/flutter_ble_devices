//
//  ICSkipDeviceInfo.h
//  ICDeviceManager
//
//  Created by symons on 2023/6/27.
//  Copyright © 2023 Symons. All rights reserved.
//

#import "ICDeviceInfo.h"
NS_ASSUME_NONNULL_BEGIN

@interface ICSkipDeviceInfo : ICDeviceInfo
/**
 * Maximum supported jump-rope count.
 */
@property (nonatomic, assign) NSUInteger maxSkipCount;

@end

NS_ASSUME_NONNULL_END
