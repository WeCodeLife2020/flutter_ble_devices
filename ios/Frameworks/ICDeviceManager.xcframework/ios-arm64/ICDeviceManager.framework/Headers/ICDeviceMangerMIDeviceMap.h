//
//  ICDeviceMangerMIDeviceMap.h
//  ICDeviceManager
//
//  Created by symons on 2023/7/17.
//  Copyright © 2023 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICDeviceMangerMIDeviceMap : NSObject

/**
 Device type.
 */
@property (nonatomic, assign) ICDeviceType type;

/**
 Device communication method.
 */
@property (nonatomic, assign) ICDeviceCommunicationType communicationType;

/**
 Device sub-type.
 */
@property (nonatomic, assign) int subType;

/**
 Other flag bits.
 */
@property (nonatomic, assign) NSUInteger otherFlag;

/**
 MIJIA product ID.
 */
@property (nonatomic, assign) NSUInteger productId;



@end

NS_ASSUME_NONNULL_END
