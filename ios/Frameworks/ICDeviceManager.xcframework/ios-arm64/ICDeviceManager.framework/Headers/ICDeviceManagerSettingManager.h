//
//  LSSettingManager.h
//  ICDeviceManager
//
//  Created by lifesense-mac on 17/3/20.
//  Copyright (c) 2017 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICModels_Inc.h"

@class ICDevice;


/**
 Setting-callback typedef

 @param code Callback result code
 */
typedef void(^ICSettingCallback)(ICSettingCallBackCode code);

/**
 Device-setting protocol
 */
@protocol ICDeviceManagerSettingManager <NSObject>

/**
 Set the scale-weight unit
 
 @param device          Device
 @param unit            Unit
 @param callback        Callback
 */
- (void)setScaleUnit:(ICDevice *)device unit:(ICWeightUnit)unit callback:(ICSettingCallback)callback;

/**
 Set the tape-measure unit
 
 @param device      Device
 @param unit        Unit
 @param callback    Callback
 */
- (void)setRulerUnit:(ICDevice *)device unit:(ICRulerUnit)unit callback:(ICSettingCallback)callback;

/**
 Set the current tape-measure body-part
 
 @param device      Device
 @param type        Body-part type
 @param callback    Callback
 */
- (void)setRulerBodyPartsType:(ICDevice *)device type:(ICRulerBodyPartsType)type callback:(ICSettingCallback)callback;

/**
 Set a weight on the kitchen scale, in milligrams

 @param device Device
 @param weight Weight in milligrams (maximum 65535 mg)
 @param callback Callback
 */
- (void)setWeight:(ICDevice *)device weight:(NSInteger)weight callback:(ICSettingCallback)callback;

/**
 Set the tare weight on the kitchen scale

 @param device Device
 @param callback Callback
 */
- (void)deleteTareWeight:(ICDevice *)device callback:(ICSettingCallback)callback;
/**
Power off the kitchen scale

@param device Device
@param callback Callback
*/
- (void)powerOffKitchenScale:(ICDevice *)device callback:(ICSettingCallback)callback;

/**
 Set the kitchen-scale measurement unit

 @param device Device
 @param unit Unit. Has no effect if the scale does not support the given unit.
 @param callback Callback
 */
- (void)setKitchenScaleUnit:(ICDevice *)device unit:(ICKitchenScaleUnit)unit callback:(ICSettingCallback)callback;

/**
 Push a nutrition-fact value to the kitchen scale

 @param device Device
 @param type Nutrition type
 @param value Nutrition value
 @param callback Callback
 */
//- (void)setNutritionFacts:(ICDevice *)device type:(ICKitchenScaleNutritionFactType)type value:(NSInteger)value callback:(ICSettingCallback)callback;

/**
 Set the tape-measure measurement mode
 
 @param device      Device
 @param mode        Measurement mode
 @param callback    Callback
 */
- (void)setRulerMeasureMode:(ICDevice *)device mode:(ICRulerMeasureMode)mode callback:(ICSettingCallback)callback;


/**
 * Start rope-skipping
 * @param device Device
 * @param mode   Rope-skipping mode
 * @param param  Mode parameter
 * @param callback Callback
 */
- (void)startSkip:(ICDevice *)device mode:(ICSkipMode)mode param:(NSUInteger)param callback:(ICSettingCallback)callback;


/**
 * Start rope-skipping
 * @param device Device
 * @param param  Mode parameter
 * @param callback Callback
 */
- (void)startSkipExt:(ICDevice *)device param:(ICSkipParam *)param callback:(ICSettingCallback)callback;


/**
 * Pause rope-skipping
 * @param device Device
 * @param callback Callback
 */
//- (void)pauseSkip:(ICDevice *)device callback:(ICSettingCallback)callback;



/**
 * Resume rope-skipping
 * @param device Device
 * @param callback Callback
 */
//- (void)resumeSkip:(ICDevice *)device callback:(ICSettingCallback)callback;



/**
 * Stop rope-skipping
 * @param device Device
 * @param callback Callback
 */
- (void)stopSkip:(ICDevice *)device callback:(ICSettingCallback)callback;

/**
 Push user info to the device
 Currently supported only by skipping ropes and some scales.

@param device       Device
@param userInfo  User info
@param callback  Callback
*/
- (void)setUserInfo:(ICDevice *)device userInfo:(ICUserInfo *)userInfo callback:(ICSettingCallback)callback;


/**
 Push a user list to the device
 Currently supported only by skipping ropes and some scales.

@param device       Device
@param userInfos  User-info list
@param callback  Callback
*/
- (void)setUserList:(ICDevice *)device userInfos:(NSArray<ICUserInfo *> *)userInfos callback:(ICSettingCallback)callback;


/**
 Provision device Wi-Fi

@param device        Device
@param mode             Provisioning mode
@param ssid             Wi-Fi SSID
@param password    Wi-Fi password
@param method        Encryption method
*/
- (void)configWifi:(ICDevice *)device mode:(ICConfigWifiMode)mode ssid:(NSString *)ssid password:(NSString *)password method:(int)method callback:(ICSettingCallback)callback;

/**
 Set vendor-specific parameters

 @param device      Device
 @param type        Meaning is vendor-specific
 */
- (void)setOtherParams:(ICDevice *)device type:(NSUInteger)type param:(NSObject *)param callback:(ICSettingCallback)callback;


/**
 * Set the skipping-rope light effects
 * @param device Device
 * @param param Parameters
 * @param callback Callback
 */
- (void)setDeviceLightSetting:(ICDevice *)device param:(NSObject *)param callback:(ICSettingCallback)callback;


/**
 * Set the device UI items
 * @param device Device
 * @param items UI items
 * @param callback Callback
 */
- (void)setScaleUIItems:(ICDevice *)device items:(NSArray<NSNumber *> *)items callback:(ICSettingCallback)callback;

/*
 * Prepare broadcast
 * @param device    Base-station device
 * @param callback  Callback
 */
- (void)lockStSkip:(ICDevice *)device callback:(ICSettingCallback)callback;


/*
 * Prepare broadcast(Only supported by a subset of models.)
 * @param device    Base-station device
 * @param param    Parameter lock
 * @param callback  Callback
 */
- (void)lockStSkipEx:(ICDevice *)device param:(ICSkipParam *)param callback:(ICSettingCallback)callback;

/*
 * Query the online state of every node
 * @param device    Base-station device
 * @param callback  Callback
 */
- (void)queryStAllNode:(ICDevice *)device callback:(ICSettingCallback)callback;

/*
 * Change the advertised name
 * @param device    Base-station device
 * @param name      Advertised name
 * @param callback  Callback
 */
- (void)changeStName:(ICDevice *)device name:(NSString *)name callback:(ICSettingCallback)callback;

/*
 * Change a node ID
 * @param device    Base-station device
 * @param dstId     New node ID
 * @param callback  Callback
 */
- (void)changeStNo:(ICDevice *)device dstId:(NSUInteger)dstId  st_no:(NSUInteger)st_no callback:(ICSettingCallback)callback;

/**
 * Set the skipping-rope sound effects
 * @param device Device
 * @param config Sound-effect configuration
 * @param callback Callback
 */
- (void)setSkipSoundSetting:(ICDevice *)device config:(ICSkipSoundSettingData *)config callback:(ICSettingCallback)callback;


/**
* Set the skipping-rope heart-rate upper limit
 * @param device Device
 * @param hr Heart-rate upper limit
 * @param callback Callback
 */
- (void)setHRMax:(ICDevice *)device hr:(int)hr callback:(ICSettingCallback)callback;


/**
 * Set the skipping-rope BPM
 * @param device Device
 * @param type Metronome type
 * @param bpm Metronome BPM
 * @param callback Callback
 */
- (void)setBPM:(ICDevice *)device type:(ICBPMType)type bpm:(int)bpm callback:(ICSettingCallback)callback;


/**
 * Set the volume
 * @param device Device
 * @param volume Volume in the 0-100 range
 * @param callback Callback
 */
- (void)setVolume:(ICDevice *)device volume:(int)volume callback:(ICSettingCallback)callback;


/**
 * Set the skipping-rope announcement frequency
 * @param device Device
 * @param freq  Announce every N jumps; supported values: 50, 100, 150, 200
 * @param callback Callback
 */
- (void)setSkipPlayFreq:(ICDevice *)device freq:(int)freq callback:(ICSettingCallback)callback;



/**
 * Set the heart rate
 * @param device Device
 * @param hr Current heart rate
 * @param callback Callback
 */
- (void)setHR:(ICDevice *)device hr:(int)hr callback:(ICSettingCallback)callback;





/*
 * Change the nickname/avatar for a given node
 * @param device    Base-station device
 * @param nodeId     Node ID
 * @param nickName    Nickname
 * @param headType     Avatar index
 * @param callback  Callback
 */
- (void)setNickNameInfo:(ICDevice *)device nodeId:(NSUInteger)nodeId nickName:(NSString *)nickName headType:(NSUInteger)headType  sclass:(NSUInteger)sclass grade:(NSUInteger)grade studentNo:(NSUInteger)studentNo callback:(ICSettingCallback)callback;


/*
 * Dissolve the base-station network
 * @param device    Base-station device
 * @param callback  Callback
 */
- (void)exitNetwork:(ICDevice *)device callback:(ICSettingCallback)callback;


/*
 * Remove the given nodes
 * @param device    Base-station device
 * @param nodeIds     List of node IDs
 * @param callback  Callback
 */
- (void)removeNodeIds:(ICDevice *)device nodeIds:(NSArray<NSNumber *> *)nodeIds callback:(ICSettingCallback)callback;



/*
 * Configure the root node
 * @param device    Base-station device
 * @param matchMode Base-station running mode
 * @param callback  Callback
 */
- (void)setRootNodeId:(ICDevice *)device matchMode:(NSUInteger)matchMode callback:(ICSettingCallback)callback;

/*
 * Configure a client node
 * @param device    Base-station device
 * @param callback  Callback
 */
- (void)setClientNodeId:(ICDevice *)device callback:(ICSettingCallback)callback;


/*
 * Read nickname and avatar
 * @param device    Base-station device
 * @param callback  Callback
 */
- (void)readUserInfo:(ICDevice *)device callback:(ICSettingCallback)callback;


/*
 * Bind a heart-rate device (only for base-station skipping ropes with the three-in-one firmware).
 * @param device            Base-station device
 * @param nodeId            Node ID to bind a heart-rate device to
 * @param hrDeviceMac       Heart-rate device MAC
 * @param callback          Callback
 */
- (void)bindHRDevice:(ICDevice *)device nodeId:(NSUInteger)nodeId hrDeviceMac:(NSString *)hrDeviceMac callback:(ICSettingCallback)callback;



/*
 * Set the scale voice type
 * @param device
 * @param config Sound-effect configuration
 * @param callback
 */
- (void)setScaleSoundSetting:(ICDevice *)device config:(ICScaleSoundSettingData *)config callback:(ICSettingCallback)callback;


/*
 * Set the scale decryption key
 * @param device
 * @param key Key
 * @param callback
 */
- (void)setDeviceKey:(ICDevice *)device key:(NSString *)key callback:(ICSettingCallback)callback;

/*
 * Send data to the scale
 * @notice Only one send can be in flight per device; wait for the previous call to complete before issuing another.
 * @param device
 * @param type Data type
 * @param userId Associated user ID. Some data types do not need it; pass 0 in that case.
 * @param obj Payload whose concrete type is determined by `type`; see the type description for details
 * @param callback
 */
- (void)sendData:(ICDevice *)device type:(ICSendDataType)type userId:(NSUInteger)userId obj:(NSObject *)obj  callback:(ICSettingCallback)callback;

/*
 * Send data to the scale
 * @notice Only one send can be in flight per device; wait for the previous call to complete before issuing another.
 * @param device
 * @param type Data type
 * @param userId Associated user ID. Some data types do not need it; pass 0 in that case.
 * @param foodId Associated food ID
 * @param foodIndex Associated food index
 * @param obj Payload whose concrete type is determined by `type`; see the type description for details
 * @param callback
 */
- (void)sendKitchenScaleData:(ICDevice *)device type:(ICSendDataType)type userId:(NSUInteger)userId foodId:(NSUInteger)foodId foodIndex:(NSUInteger)foodIndex obj:(NSObject *)obj  callback:(ICSettingCallback)callback;

/*
 * Send an HTTPS certificate
 * cerVersion Certificate version number
 * filePath Certificate file path
 * @param callback
 */
- (void)sendHttpsCertificateData:(ICDevice *)device cerVersion:(NSUInteger)cerVersion filePath:(NSString *)filePath callback:(ICSettingCallback)callback;

/*
 * Cancel a pending data send
 * @param device
 * @param callback
 */
- (void)cancelSendData:(ICDevice *)device callback:(ICSettingCallback)callback;

/*
 * Issue an engineering / service command
 * @param device
 * @param param Parameters
 * @param callback
 */
- (void)setCommand:(ICDevice *)device cmd:(NSUInteger)cmd param:(NSObject *)param callback:(ICSettingCallback)callback;


/**
 * Update or add a user on a W-series device
 * @param device Device
 * @param userInfo User info
 * @param callback Callback
 */
- (void)updateUserInfo_W:(ICDevice *)device userInfo:(ICUserInfo *)userInfo callback:(ICSettingCallback)callback;

/**
 * Set the current user on a W-series device
 * @param device Device
 * @param userInfo Current user info
 * @param callback Callback
 */
- (void)setCurrentUserInfo_W:(ICDevice *)device userInfo:(ICUserInfo *)userInfo callback:(ICSettingCallback)callback;

/**
 * Remove a user from a W-series device
 * @param device Device
 * @param userId User ID
 * @param callback Callback
 */
- (void)deleteUser_W:(ICDevice *)device userId:(NSUInteger)userId callback:(ICSettingCallback)callback;

/**
 * Query the W-series user list. The list is delivered via onReceiveUserInfoList.
 * @param device Device
 * @param callback Callback
 */
- (void)getUserList_W:(ICDevice *)device callback:(ICSettingCallback)callback;

/**
 * Start a Wi-Fi scan on a W-series device. The Wi-Fi list is delivered via onReceiveScanWifiInfo_W.
 * @param device Device
 * @param callback Callback
 */
- (void)startScanWifi_W:(ICDevice *)device callback:(ICSettingCallback)callback;
/**
  * Stop scanning Wi-Fi on a W-series device
  * @param device Device
  * @param callback Callback
  */
- (void)stopScanWifi_W:(ICDevice *)device callback:(ICSettingCallback)callback;

/**
 * Configure Wi-Fi on a W-series device. The provisioning state is delivered via onReceiveCurrentWifiInfo_W.
 * @param device    Device
 * @param ssid      SSID to connect to
 * @param password  Password
 * @param method    Encryption method. Use the value reported by onReceiveScanWifiInfo_W.
 * @param callback  Callback
 */
- (void)configWifi_W:(ICDevice *)device ssid:(NSString *)ssid password:(NSString *)password method:(NSInteger)method callback:(ICSettingCallback)callback;

/**
 * Toggle the W-series welcome screen
 * @param device Device
 * @param enable Whether to show it
 * @param callback Callback
 */
- (void)setHello_W:(ICDevice *)device enable:(BOOL)enable callback:(ICSettingCallback)callback;
/**
 * Set the W-series power mode
 * @param device Device
 * @param isNormal Whether to enter low-power mode
 * @param callback Callback
 */
- (void)setPowerMode_W:(ICDevice *)device isNormal:(BOOL)isNormal callback:(ICSettingCallback)callback;
/**
 * Set the W-series display items
 * @param device Device
 * @param items Display items
 * @param callback Callback
 */
- (void)setScreen_W:(ICDevice *)device items:(NSArray<NSNumber *> *)items callback:(ICSettingCallback)callback;
/**
 * Wake a W-series device
 * @param device Device
 * @param callback Callback
 */
- (void)wakeupScreen_W:(ICDevice *)device callback:(ICSettingCallback)callback;
/**
 * Set the W-series screen-on duration
 * @param device Device
 * @param time   Duration in seconds
 * @param callback Callback
 */
- (void)setScreenTime_W:(ICDevice *)device time:(NSUInteger)time callback:(ICSettingCallback)callback;
/**
 * Mark a W-series device as bound. Updates the binding flag so the device reports as bound via bindStatus in scan results and via queryBindStatus_W.
 * @param device Device
 * @param callback Callback
 */
- (void)bindDevice_W:(ICDevice *)device callback:(ICSettingCallback)callback;
/**
* Query the W-series binding state. The state is delivered via onReceiveBindState_W.
* @param device Device
* @param callback Callback
*/
- (void)queryBindStatus_W:(ICDevice *)device callback:(ICSettingCallback)callback;
/**
 * Reset a W-series device
 * @param device Device
 * @param callback Callback
 */
- (void)reset_W:(ICDevice *)device callback:(ICSettingCallback)callback;

/**
 * Wipe all W-series user data
 * @param device Device
 * @param callback Callback
 */
- (void)deleteAllUser_W:(ICDevice *)device callback:(ICSettingCallback)callback;

/**
 * Start an OTA upgrade on a W-series device
 * @param device Device
 * @param currentVersion Current firmware version
 * @param newVersion New firmware version
 * @param callback Callback
 */
- (void)startUpgrade_W:(ICDevice *)device currentVersion:(NSString *)currentVersion newVersion:(NSString *)newVersion callback:(ICSettingCallback)callback;

/**
 * Read history data. Check DeviceInfo to find out whether this is supported.
 * @param device Device
 */
- (void)readHistoryData:(ICDevice *)device callback:(ICSettingCallback)callback;

/**
 * Set nutrition data
 * @param device Device
 * @param foodId Food ID
 * @param facts Nutrition-fact list
 * @param callback Callback
 */
- (void)setNutritionFacts:(ICDevice *)device foodId:(NSUInteger)foodId facts:(NSArray<ICNutritionFact *> *)facts callback:(ICSettingCallback)callback;

/**
 * Set nutrition data for N grams of a food
 * @param device Device
 * @param foodId Food ID
 * @param name Food name
 * @param icon Food image
 * @param weight Weight in grams
 * @param facts Nutrition-fact list
 * @param callback Callback
 */
- (void)setNutritionFactsInUnit:(ICDevice *)device foodId:(NSUInteger)foodId name:(NSString *)name icon:(NSString *)icon weight:(NSUInteger)weight facts:(NSArray<ICNutritionFact *> *)facts callback:(ICSettingCallback)callback;

/**
 * Update nutrition data for a common food (per N grams)
 * @param device Device
 * @param foodIndex Food index
 * @param foodId Food ID
 * @param name Food name
 * @param icon Food image
 * @param weight Weight in grams
 * @param facts Nutrition-fact list
 * @param callback Callback
 */
- (void)setCommonNutritionFacts:(ICDevice *)device foodIndex:(NSUInteger)foodIndex foodId:(NSUInteger)foodId name:(NSString *)name icon:(NSString *)icon weight:(NSUInteger)weight facts:(NSArray<ICNutritionFact *> *)facts callback:(ICSettingCallback)callback;

/**
 * Delete common foods
 * @param device Device
 * @param foods Foods to remove
 * @param callback Callback
 */
- (void)deleteCommonNutritionFacts:(ICDevice *)device foods:(NSArray<ICFoodInfo *> *)foods callback:(ICSettingCallback)callback;

/**
 * Reorder common foods
 * @param device Device
 * @param foods Food order
 * @param callback Callback
 */
- (void)setCommonNutritionFactsOrder:(ICDevice *)device foods:(NSArray<ICFoodInfo *> *)foods callback:(ICSettingCallback)callback;

/**
 * Set the intake history list
 * @param device Device
 * @param rniList Intake list
 * @param callback Callback
 */
- (void)setRNIHistory:(ICDevice *)device userId:(NSUInteger)userId rniList:(NSArray<ICRNIHistoryData *> *)rniList callback:(ICSettingCallback)callback;

/**
 * Confirm the food
 * @param device Device
 * @param callback Callback
 */
- (void)confirmFood:(ICDevice *)device  callback:(ICSettingCallback)callback;

/**
 * Read the common-foods list
 * @param device Device
 * @param callback Callback
 */
- (void)readCommonFoods:(ICDevice *)device  callback:(ICSettingCallback)callback;

/**
 * Set the number of foods to send
 * @param device Device
 * @param count Number of foods
 * @param callback Callback
 */
- (void)setSendFoodsCount:(ICDevice *) device count:(NSUInteger)count callback:(ICSettingCallback)callback;

/**
 * Set the current UI page on the device
 * @param device Device
 * @param page Page
 * @param callback Callback
 */
- (void)setCurrentPage:(ICDevice *)device page:(NSUInteger)page callback:(ICSettingCallback)callback;

/**
 * Wake the device
 * @param device Device
 * @param callback Callback
 */
- (void)wakeupScreen:(ICDevice *)device callback:(ICSettingCallback)callback;

@end
