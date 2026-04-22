//
//  ICWifiInfoData.h
//  ICDeviceManager
//
//  Created by Guobin Zheng on 2025/2/27.
//  Copyright © 2025 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 Wi-Fi information data.
 */
@interface ICWifiInfoData : NSObject

/**
 Wi-Fi SSID.
 */
@property (nonatomic, strong) NSString *ssid;
/**
 Signal strength (RSSI).
 */
@property (nonatomic, assign) NSInteger rssi;
/**
 Encryption method.
 (Used in scanned Wi-Fi info.)
 */
@property (nonatomic, assign) NSUInteger method;
/**
 Status. 0: not configured, 1: Wi-Fi not connected, 2: Wi-Fi connected but server not connected, 3: server connected, 4: Wi-Fi module not powered.
 (Used in current Wi-Fi info.)
 */
@property (nonatomic, assign) NSInteger status;
/**
 IP address.
 (Used in current Wi-Fi info.)
 */
@property (nonatomic, strong) NSString *ip;

@end

NS_ASSUME_NONNULL_END
