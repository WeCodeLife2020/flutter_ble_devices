//
//  ICDeviceManagerDelegate.h
//  ICDeviceManager
//
//  Created by Symons on 2018/7/28.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICModels_Inc.h"

@protocol ICDeviceManagerDelegate <NSObject>

@required
/**
 SDK initialisation-complete callback.

 @param bSuccess Whether initialisation succeeded.
 */
- (void)onInitFinish:(BOOL)bSuccess;

@optional

/**
 Bluetooth state-change callback.

 @param state Bluetooth state.
 */
- (void)onBleState:(ICBleState)state;

/**
 Device connection-state callback.

 @param device Device.
 @param state  Connection state.
 */
- (void)onDeviceConnectionChanged:(ICDevice *)device state:(ICDeviceConnectState)state;

/**
 Node-device connection-state callback.

 @param device Device.
 @param nodeId Node identifier.
 @param state  Connection state.
 */
- (void)onNodeConnectionChanged:(ICDevice *)device nodeId:(NSUInteger)nodeId state:(ICDeviceConnectState)state;


/**
 Body-weight scale data callback.

 @param device Device.
 @param data   Measurement data.
 */
- (void)onReceiveWeightData:(ICDevice *)device data:(ICWeightData *)data;


/**
 Kitchen-scale data callback.

 @param device Device.
 @param data   Measurement data.
 */
- (void)onReceiveKitchenScaleData:(ICDevice *)device data:(ICKitchenScaleData *)data;


/**
 Kitchen-scale history-data callback.

 @param device Device.
 @param datas  List of historical readings.
 */
- (void)onReceiveKitchenScaleHistoryData:(ICDevice *)device datas:(NSArray<ICKitchenScaleData *> *)datas;


/**
 Kitchen-scale unit-changed callback.

 @param device Device.
 @param unit   New unit.
 */
- (void)onReceiveKitchenScaleUnitChanged:(ICDevice *)device unit:(ICKitchenScaleUnit)unit;

/**
 Kitchen-scale food list callback.

 @param device Device.
 @param foods  Food list.
 */
- (void)onReceiveKitchenScaleCommonFoods:(ICDevice *)device foods:(NSArray<ICFoodInfo *> *)foods;


/**
 Balance-scale coordinate callback.

 @param device Device.
 @param data   Coordinate data.
 */
- (void)onReceiveCoordData:(ICDevice *)device data:(ICCoordData *)data;

/**
 Tape-measure data callback.

 @param device Device.
 @param data   Measurement data.
 */
- (void)onReceiveRulerData:(ICDevice *)device data:(ICRulerData *)data;

/**
 Tape-measure history-data callback.

 @param device Device.
 @param data   Measurement data.
 */
- (void)onReceiveRulerHistoryData:(ICDevice *)device data:(ICRulerData *)data;

/**
 Balance / centre-of-gravity data callback.

 @param device Device.
 @param data   Balance data.
 */
- (void)onReceiveWeightCenterData:(ICDevice *)device data:(ICWeightCenterData *)data;

/**
 Device unit-changed callback.

 @param device Device.
 @param unit   Current device unit.
 */
- (void)onReceiveWeightUnitChanged:(ICDevice *)device unit:(ICWeightUnit)unit;


/**
 Tape-measure unit-changed callback.

 @param device Device.
 @param unit   Current device unit.
 */
- (void)onReceiveRulerUnitChanged:(ICDevice *)device unit:(ICRulerUnit)unit;

/**
 Tape-measure mode-changed callback.

 @param device Device.
 @param mode   Current measurement mode.
 */
- (void)onReceiveRulerMeasureModeChanged:(ICDevice *)device mode:(ICRulerMeasureMode)mode;


/**
 Per-electrode (4-sensor) data callback.

 @param device Device.
 @param data   Electrode data.
 */
- (void)onReceiveElectrodeData:(ICDevice *)device data:(ICElectrodeData *)data;

/**
 Step-wise callback delivering weight, balance, impedance and heart-rate data.

 @param device Device.
 @param step   Current measurement step.
 @param data   Step payload (see ICMeasureStep for the concrete class).
 */
- (void)onReceiveMeasureStepData:(ICDevice *)device step:(ICMeasureStep)step data:(NSObject *)data;

/**
 Weight-history-data callback.

 @param device Device.
 @param data   Historical weight data.
 */
- (void)onReceiveWeightHistoryData:(ICDevice *)device data:(ICWeightHistoryData *)data;


/**
 Real-time rope-skipping data callback.

 @param device Device.
 @param data   Rope-skipping data.
 */
- (void)onReceiveSkipData:(ICDevice *)device data:(ICSkipData *)data;


/**
 Rope-skipping history-data callback.

 @param device Device.
 @param data   Historical rope-skipping data.
 */
- (void)onReceiveHistorySkipData:(ICDevice *)device data:(ICSkipData *)data;

/**
 Rope-skipping battery level. Superseded by onReceiveBattery.

 @param device  Device.
 @param battery Battery percentage in the range 0-100.
 */
//- (void)onReceiveSkipBattery:(ICDevice *)device battery:(NSUInteger)battery;

/**
 Battery-level callback.

 @param device  Device.
 @param battery Battery percentage in the range 0-100.
 @param ext     Extension payload. For station-based skipping ropes this is the node ID boxed as NSNumber.
 */
- (void)onReceiveBattery:(ICDevice *)device battery:(NSUInteger)battery ext:(NSObject *)ext;

/**
 Device OTA upgrade-status callback.

 @param device  Device.
 @param status  Upgrade status.
 @param percent Upgrade progress in the range 0-100.
 */
- (void)onReceiveUpgradePercent:(ICDevice *)device status:(ICUpgradeStatus)status percent:(NSUInteger)percent;

/**
 Device-info callback.

 @param device     Device.
 @param deviceInfo Device info.
 */
- (void)onReceiveDeviceInfo:(ICDevice *)device deviceInfo:(ICDeviceInfo *)deviceInfo;

/**
 * Wi-Fi provisioning result callback.
 * @param device Device.
 * @param type   Provisioning data type.
 * @param obj    Payload.
 */
- (void)onReceiveConfigWifiResult:(ICDevice *)device type:(ICConfigWifiResultType)type obj:(NSObject *)obj;


/**
 Heart-rate callback.

 @param device Device.
 @param hr     Heart rate in the range 0-255.
 */
- (void)onReceiveHR:(ICDevice *)device hr:(int)hr;


/**
 User-info upload callback (sports-edition skipping ropes).

 @param device   Device.
 @param userInfo User info.
 */
- (void)onReceiveUserInfo:(ICDevice *)device userInfo:(ICUserInfo *)userInfo;

/**
 User-info list upload callback. The entries contain only a subset of user fields.

 @param device    Device.
 @param userInfos User-info list.
 */
- (void)onReceiveUserInfoList:(ICDevice *)device userInfos:(NSArray<ICUserInfo *> *)userInfos;

/**
 Device RSSI callback.

 @param device Device.
 @param rssi   Signal strength.
 */
- (void)onReceiveRSSI:(ICDevice *)device rssi:(int)rssi;


/**
   Debug-data callback.

   @param device Device.
   @param type   Data type.
   @param obj    Payload.
   */
- (void)onReceiveDebugData:(ICDevice *)device type:(int)type obj:(NSObject *)obj;

/**
   Device-light configuration callback.

   @param device Device.
   @param obj    Light parameters.
 */
- (void)onReceiveDeviceLightSetting:(ICDevice *)device obj:(NSObject *)obj;


/**
 * Wi-Fi scan-result callback (W-series devices).
 * @param device Device.
 * @param ssid   Wi-Fi SSID.
 * @param method Encryption method.
 * @param rssi   Signal strength.
 */
- (void)onReceiveScanWifiInfo_W:(ICDevice *)device ssid:(NSString *)ssid method:(NSInteger)method rssi:(NSUInteger)rssi;

/**
 * Current-Wi-Fi callback (W-series devices).
 * @param device Device.
 * @param status Status. 0: not provisioned, 1: Wi-Fi not connected, 2: Wi-Fi connected but server not reachable, 3: server connected, 4: Wi-Fi module not powered.
 * @param ip     IP address.
 * @param ssid   SSID.
 * @param rssi   Signal strength.
 */
- (void)onReceiveCurrentWifiInfo_W:(ICDevice *)device status:(NSUInteger)status ip:(NSString *)ip ssid:(NSString *)ssid  rssi:(NSInteger)rssi;
/**
 * Binding-state callback.
 * @param device Device.
 * @param status Binding state. 1: bound, 0: not bound.
 */
- (void)onReceiveBindState_W:(ICDevice *)device status:(NSUInteger)status;
/**
  * Current UI page-ID change callback.
  * @param device Device.
  * @param pageId UI page identifier.
  */
- (void)onReceiveCurrentPage:(ICDevice *)device pageId:(NSUInteger)pageId;

@end
