//
//  ICDeviceManagerConfig.h
//  ICDeviceManager
//
//  Created by Symons on 2018/7/28.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

@class ICDeviceMangerMIDeviceMap;

/**
 SDK configuration class.
 */
@interface ICDeviceManagerConfig : NSObject

/**
 When Bluetooth is off, whether iOS should show the "Bluetooth is off" alert on app launch. Default: YES.
 */
@property (nonatomic, assign) BOOL isShowPowerAlert;


/**
 Whether the SDK should auto-fill the impedance reading for connected scales. Default: NO.
 */
@property (nonatomic, assign) BOOL is_fill_adc;


/**
 SDK mode.
 */
@property (nonatomic, assign) ICSDKMode sdkMode;


/**
 * RSSI auto-read interval (ms) for connected devices. Default: 5000.
 */
@property (nonatomic, assign) int rssiRefreshSpeed;


/**
 Register a MIJIA product-id mapping.
 */
- (void)addMIDevice:(ICDeviceMangerMIDeviceMap *)deviceMap;

/**
 Look up a MIJIA product-id mapping.
 */
- (ICDeviceMangerMIDeviceMap *)getMIDeviceByProductId:(NSUInteger)productId;

- (NSArray<ICDeviceMangerMIDeviceMap *> *)getMIDevices;

@end
