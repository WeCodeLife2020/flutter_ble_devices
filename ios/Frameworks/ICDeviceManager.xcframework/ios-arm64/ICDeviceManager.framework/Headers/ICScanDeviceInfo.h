//
//  ICScanDeviceInfo.h
//  ICDeviceManager
//
//  Created by Symons on 2018/7/28.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

/**
 Information about a scanned Bluetooth device.
 */
@interface ICScanDeviceInfo : NSObject

/**
 Advertised name.
 */
@property (nonatomic, strong) NSString *name;

/**
 Device type.
 */
@property (nonatomic, assign) ICDeviceType type;

/**
 Device sub-type.
 */
@property (nonatomic, assign) ICDeviceSubType subType;

/**
 Device communication method.
 */
@property (nonatomic, assign) ICDeviceCommunicationType communicationType;
    
/**
 MAC address.
 */
@property (nonatomic, strong) NSString *macAddr;

/**
 Service UUID list.
 */
@property (nonatomic, strong) NSArray<NSString *> *services;

/**
 Signal strength (RSSI). 0: system-paired device. -128: invalid RSSI.
 */
@property (nonatomic, assign) NSInteger rssi;

/**
 Base-station random code.
*/
@property (nonatomic, assign) NSUInteger st_no;

/**
 Node ID.
*/
@property (nonatomic, assign) NSUInteger nodeId;

/**
 Device flag; 0 means none.
 */
@property (nonatomic, assign) NSUInteger deviceFlag;

/**
 *  Device function codes.
 */
@property (nonatomic, copy)  NSArray<NSNumber *> *deviceFunctions;

/**
 Binding status. 0: not bound, 1: bound, 2: query unsupported.
*/
@property (nonatomic, assign) NSUInteger bindStatus;


@end
