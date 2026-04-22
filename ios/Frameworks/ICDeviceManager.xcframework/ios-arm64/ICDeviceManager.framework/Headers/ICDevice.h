//
//  ICDevice.h
//  ICDeviceManager
//
//  Created by Symons on 2018/7/28.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Icomon (Welland) device class.
 */
@interface ICDevice : NSObject

/**
 Device MAC address.
 */
@property (nonatomic, copy) NSString *macAddr;

@end
