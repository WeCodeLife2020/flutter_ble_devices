//
//  ICDeviceManager.h
//  ICDeviceManager
//
//  Created by Symons on 2018/7/27.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICDeviceManagerDelegate.h"
#import "ICDeviceManagerSettingManager.h"
#import "ICModels_Inc.h"
#import "ICCallback_Inc.h"
#import "ICBodyFatAlgorithmsManager.h"

@interface ICDeviceManager : NSObject

/**
 Data and state callback delegate.
 */
@property (nonatomic, weak) id<ICDeviceManagerDelegate> delegate;

/**
 Set the SDK running mode.
 */
- (void)setSDKMode:(ICSDKMode)sdkMode;

/**
 Return the SDK running mode.
 */
- (ICSDKMode)getSDKMode;

/**
 Shared Bluetooth device manager instance.

 @return The singleton instance.
 */
+ (instancetype)shared;

/**
 Initialise the SDK with default configuration.
 */
- (void)initMgr;

/**
 Initialise the SDK with a config object.

 @param config Configuration.
 */
- (void)initMgrWithConfig:(ICDeviceManagerConfig *)config;

/**
 Release SDK resources.
*/
- (void)deInit;

/**
 Update the current user info.

 @param userInfo User info.
 */
- (void)updateUserInfo:(ICUserInfo *)userInfo;

- (void)setUserList:(NSArray<ICUserInfo *> *)userlist;

/**
 Start scanning for devices.

 @param delegate Scan-result delegate.
 */
- (void)scanDevice:(id<ICScanDeviceDelegate>)delegate;

/**
 Stop scanning.
 */
- (void)stopScan;

/**
 Add a device.
 */
- (void)addDevice:(ICDevice *)device callback:(ICAddDeviceCallBack)callback;

/**
 Add a list of devices. The block is invoked once per device.
 */
- (void)addDevices:(NSArray<ICDevice *> *)devices callback:(ICAddDeviceCallBack)callback;

/**
 Remove a device.
 */
- (void)removeDevice:(ICDevice *)device callback:(ICRemoveDeviceCallBack)callback;

/**
 Remove a list of devices. The block is invoked once per device.
 */
- (void)removeDevices:(NSArray<ICDevice *> *)devices callback:(ICRemoveDeviceCallBack)callback;

- (void)upgradeDevice:(ICDevice *)device filePath:(NSString *)filePath mode:(ICOTAMode)mode;

- (void)stopUpgradeDevice:(ICDevice *)device;

- (void)upgradeDevices:(NSArray<ICDevice *> *)devices filePath:(NSString *)filePath mode:(ICOTAMode)mode;


/**
 Return the device-setting protocol instance.

 @return Setting-manager instance.
 */
- (id<ICDeviceManagerSettingManager>)getSettingManager;

/**
 Return the body-fat algorithm protocol instance.

 @return Body-fat algorithm instance.
 */
- (id<ICBodyFatAlgorithmsManager>)getBodyFatAlgorithmsManager;

/**
 Whether Bluetooth is on.
 @notice Only call after the init callback reports success; otherwise the return value is NO.
 */
- (BOOL)isBLEEnable;

/**
 SDK version.

 @return SDK version string.
 */
+ (NSString *)version;

/**
 Path of the SDK log directory. Only the last 7 days of logs are retained.

 @return Log-directory path.
 */
- (NSString *)getLogPath;

@end
