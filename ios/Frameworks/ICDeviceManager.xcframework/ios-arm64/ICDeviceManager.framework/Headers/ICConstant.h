//
//  ICConstant.h
//  ICDeviceManager
//
//  Created by Symons on 2018/7/28.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#ifndef ICConstant_h
#define ICConstant_h

#import "ICAlgDef.h"

@class ICDevice;


/**
 Device type
 **/
typedef NS_ENUM(NSUInteger, ICDeviceType)
{
    /**
     * Unknown
     **/
    ICDeviceTypeUnKnown = 0,
    
    /**
     * Weight scale
     **/
    ICDeviceTypeWeightScale,
    
    /**
     * Body-fat scale
     **/
    ICDeviceTypeFatScale,

    /**
     * Body-fat scale with temperature display
     **/
    ICDeviceTypeFatScaleWithTemperature,
    
    /**
     * Kitchen scale
     **/
    ICDeviceTypeKitchenScale,

    /**
     * Tape measure
     **/
    ICDeviceTypeRuler,

    /**
     * Balance scale
     **/
    ICDeviceTypeBalance,

    /**
     * Skipping rope
     **/
    ICDeviceTypeSkip,

    /**
     * HR (heart-rate strap / heart-rate device)
     **/
    ICDeviceTypeHR,
    
    /**
     * Sphygmomanometer (blood-pressure monitor)
     **/
    ICDeviceTypeSphygmomanometer,
};

/**
 Device sub-type
 **/
typedef NS_ENUM(NSUInteger, ICDeviceSubType)
{
    /**
     * Default
     **/
    ICDeviceSubTypeDefault = 0,
    
    /**
     * 8-electrode device
     **/
    ICDeviceSubTypeEightElectrode,
    
    /**
     * Height-enabled device
     **/
    ICDeviceSubTypeHeight,
    /**
     * 8-electrode device (variant 2)
     **/
    ICDeviceSubTypeEightElectrode2,
    /**
     * Dual-mode device
     **/
    ICDeviceSubTypeScaleDual,
    /**
     * Skipping rope with light effects
     **/
    ICDeviceSubTypeLightEffect,
    /**
     * Colour-display scale
     **/
    ICDeviceSubTypeColor,
    /**
     * Skipping rope with voice
     **/
    ICDeviceSubTypeSound,

    /**
     * Skipping rope with light effects and voice
     **/
    ICDeviceSubTypeLightAndSound,
    
    /**
     * Base station
    */
    ICDeviceSubTypeBaseSt,
    
    /**
     * iComon S2
    */
    ICDeviceSubTypeRopeS2,
    
    /**
     * Scale using the new protocol path
     */
    ICDeviceSubTypeNewScale,
    /**
     * W-series device
     */
    ICDeviceSubTypeW
};

/**
 Device communication mode
 
 */
typedef NS_ENUM(NSUInteger, ICDeviceCommunicationType) {
    /**
     Unknown
     */
    ICDeviceCommunicationTypeUnknown,
    
    /**
     Connection-based
     */
    ICDeviceCommunicationTypeConnect,
    
    /**
     Broadcast-based
     */
    ICDeviceCommunicationTypeBroadcast,
};

/**
 Bluetooth state
 */
typedef NS_ENUM(NSUInteger, ICBleState)
{
    /**
     * Unknown state
     **/
    ICBleStateUnknown = 0,
    
    /**
     * Phone does not support BLE
     **/
    ICBleStateUnsupported,
    
    /**
     * App has not been granted Bluetooth permission
     **/
    ICBleStateUnauthorized,
    
    /**
     * Bluetooth is off
     **/
    ICBleStatePoweredOff,
    
    /**
     * Bluetooth is on
     **/
    ICBleStatePoweredOn,
};


/**
 Device connection state
 
 */
typedef NS_ENUM(NSUInteger, ICDeviceConnectState)
{
    /**
     * Connected
     **/
    ICDeviceConnectStateConnected,
    
    /**
     * Disconnected
     **/
    ICDeviceConnectStateDisconnected,
};



/**
 * Add-device callback code
 */
typedef NS_ENUM(NSUInteger, ICAddDeviceCallBackCode)
{
    /**
     * Added successfully
     */
    ICAddDeviceCallBackCodeSuccess,
    
    /**
     * Add failed: SDK not initialised
     */
    ICAddDeviceCallBackCodeFailedAndSDKNotInit,
    
    /**
     * Add failed: device already exists
     */
    ICAddDeviceCallBackCodeFailedAndExist,
    
    /**
     * Add failed: invalid device parameters
     */
    ICAddDeviceCallBackCodeFailedAndDeviceParamError,
};

/**
 Add-device callback
 */
typedef void(^ICAddDeviceCallBack)(ICDevice *device, ICAddDeviceCallBackCode code);


/**
 * Remove-device callback code
 */
typedef NS_ENUM(NSUInteger, ICRemoveDeviceCallBackCode)
{
    /**
     * Removed successfully
     */
    ICRemoveDeviceCallBackCodeSuccess,
    
    /**
     * Remove failed: SDK not initialised
     */
    ICRemoveDeviceCallBackCodeFailedAndSDKNotInit,
    
    /**
     * Remove failed: device does not exist
     */
    ICRemoveDeviceCallBackCodeFailedAndNotExist,
    
    /**
     * Remove failed: invalid device parameters
     */
    ICRemoveDeviceCallBackCodeFailedAndDeviceParamError,
};

/**
 Remove-device callback
 */
typedef void(^ICRemoveDeviceCallBack)(ICDevice *device, ICRemoveDeviceCallBackCode code);



/**
 Setting-callback result code
 
 */
typedef NS_ENUM(NSUInteger, ICSettingCallBackCode)
{
    /**
     * Set successfully
     **/
    ICSettingCallBackCodeSuccess = 0,
    
    /**
     * Failed: SDK not initialised
     **/
    ICSettingCallBackCodeSDKNotInit,
    
    /**
     * Failed: SDK not started
     **/
    ICSettingCallBackCodeSDKNotStart,
    
    /**
     * Failed: device not found or not connected. Wait for the device to connect before applying the setting
     **/
    ICSettingCallBackCodeDeviceNotFound,
    
    /**
     * Failed: device does not support this function
     **/
    ICSettingCallBackCodeFunctionIsNotSupport,
    
    /**
     * Failed: device has disconnected
     **/
    ICSettingCallBackCodeDeviceDisConnected,
    
    /**
     * Failed: invalid parameter
     **/
    ICSettingCallBackCodeInvalidParameter,

    /**
     * Failed: wait for the previous task to finish
     **/
    ICSettingCallBackCodeWaitLastTaskOver,

    /**
     * Failed
     **/
    ICSettingCallBackCodeFailed,
};

/**
 Weight-scale unit
 */
typedef NS_ENUM(NSUInteger, ICWeightUnit)
{
    
    /**
     * Kilograms (kg)
     */
    ICWeightUnitKg = 0,
    
    /**
     * Pounds (lb)
     */
    ICWeightUnitLb,
    
    /**
     * Stones (st)
     */
    ICWeightUnitSt,
    
    /**
     * Jin (Chinese market pound)
     */
    ICWeightUnitJin
};


/**
 Tape-measure unit
 */
typedef NS_ENUM(NSUInteger, ICRulerUnit)
{
    
    /**
     * Centimetres (cm)
     */
    ICRulerUnitCM = 1,
    
    /**
     * Inches (in)
     */
    ICRulerUnitInch,
    /**
     * Feet'inches (ft'in)
     */
    ICRulerUnitFtInch,

};


/**
 Tape-measure mode
 */
typedef NS_ENUM(NSUInteger, ICRulerMeasureMode)
{
    
    /**
     * Length mode
     */
    ICRulerMeasureModeLength = 0,
    
    /**
     * Girth mode
     */
    ICRulerMeasureModeGirth,
    
};



/**
 Kitchen-scale unit
 */
typedef NS_ENUM(NSUInteger, ICKitchenScaleUnit)
{
    
    /**
     * Grams (g)
     */
    ICKitchenScaleUnitG,

    /**
     * ml
     */
    ICKitchenScaleUnitMl,

    /**
     * Pounds (lb)
     */
    ICKitchenScaleUnitLb,
    
    /**
     * Ounces (oz)
     */
    ICKitchenScaleUnitOz,
    /**
     * Milligrams (mg)
     */
    ICKitchenScaleUnitMg,
    /**
     * Millilitres (milk)
     */
    ICKitchenScaleUnitMlMilk,
    /**
     * Fluid ounces (water)
     */
    ICKitchenScaleUnitFlOzWater,
    /**
     * Fluid ounces (milk)
     */
    ICKitchenScaleUnitFlOzMilk
};


/**
 Body-part type used by the tape-measure mode
 */
typedef NS_ENUM(NSUInteger, ICRulerBodyPartsType)
{
    /**
     * Shoulder
     */
    ICRulerPartsTypeShoulder = 1,
    
    /**
     * Upper arm / bicep
     */
    ICRulerPartsTypeBicep,
    
    /**
     * Chest
     */
    ICRulerPartsTypeChest,

    /**
     * Waist
     */
    ICRulerPartsTypeWaist,
    
    /**
     * Hip
     */
    ICRulerPartsTypeHip,
    
    /**
     * Thigh
     */
    ICRulerPartsTypeThigh,
    
    /**
     * Calf
     */
    ICRulerPartsTypeCalf,
    

};

/**
 Sex
 */
typedef NS_ENUM(NSInteger,ICSexType)
{
    /**
     * Unknown / undisclosed
     */
    ICSexTypeUnknown = 0,

    /**
     * Male
     */
    ICSexTypeMale = 1,
    
    /**
     * Female
     */
    ICSexTypeFemal
};

/**
 Kitchen-scale nutrition-fact type
 */
typedef NS_ENUM(NSUInteger, ICKitchenScaleNutritionFactType) {
    /*
     *  Calories (maximum: 4294967295)
     */
    ICKitchenScaleNutritionFactTypeCalorie,
    
    /*
     *  Total calories (maximum: 4294967295)
     */
    ICKitchenScaleNutritionFactTypeTotalCalorie,
    
    /*
     *  Total fat
     */
    ICKitchenScaleNutritionFactTypeTotalFat,
    
    /*
     *  Total protein
     */
    ICKitchenScaleNutritionFactTypeTotalProtein,
    
    /*
     *  Total carbohydrates
     */
    ICKitchenScaleNutritionFactTypeTotalCarbohydrates,
    
    /*
     *  Total dietary fibre
     */
    ICKitchenScaleNutritionFactTypeTotalFiber,
    
    /*
     *  Total cholesterol
     */
    ICKitchenScaleNutritionFactTypeTotalCholesterd,
    
    /*
     *  Total sodium
     */
    ICKitchenScaleNutritionFactTypeTotalSodium,
    
    /*
     *  Total sugar
     */
    ICKitchenScaleNutritionFactTypeTotalSugar,
    
    /*
     * Fat
     */
    ICKitchenScaleNutritionFactTypeFat,
    
    /*
     * Protein
     */
    ICKitchenScaleNutritionFactTypeProtein,
    
    /*
     * Carbohydrates
     */
    ICKitchenScaleNutritionFactTypeCarbohydrates,
    
    /*
     * Dietary fibre
     */
    ICKitchenScaleNutritionFactTypeFiber,
    
    /*
     * Cholesterol
     */
    ICKitchenScaleNutritionFactTypeCholesterd,
    
    /*
     * Sodium
     */
    ICKitchenScaleNutritionFactTypeSodium,
    
    /*
     * Sugar
     */
    ICKitchenScaleNutritionFactTypeSugar,
};

/**
 Body-fat algorithm version
 */
typedef enum : NSUInteger {
#if ENABLE_WLA01
    /*
     * With-water muscle-percentage algorithm
     */
    ICBFATypeWLA01 = 0,
#endif
#if ENABLE_WLA02
    /*
     * Without-water muscle-percentage algorithm
     */
    ICBFATypeWLA02 = 1,
#endif
#if ENABLE_WLA03
    /*
     * New algorithm 1
     */
    ICBFATypeWLA03 = 2,
#endif
#if ENABLE_WLA04
    /*
     * New algorithm 2
     */
    ICBFATypeWLA04 = 3,
#endif
#if ENABLE_WLA05
    /*
     * New algorithm 3
     */
    ICBFATypeWLA05 = 4,
#endif
#if ENABLE_WLA06
    /*
     * New algorithm 4
     */
    ICBFATypeWLA06 = 5,
#endif
#if ENABLE_WLA07
    /*
     * WLA07 algorithm
     */
    ICBFATypeWLA07 = 6,
#endif
#if ENABLE_WLA08
    /*
     * WLA08 algorithm
     */
    ICBFATypeWLA08 = 7,
#endif
#if ENABLE_WLA09
    /*
     * WLA09 algorithm
     */
    ICBFATypeWLA09 = 8,
#endif
#if ENABLE_WLA10
    /*
     * WLA10 algorithm
     */
    ICBFATypeWLA10 = 9,
#endif
#if ENABLE_WLA11
    /*
     * WLA11 algorithm
     */
    ICBFATypeWLA11 = 10,
#endif
#if ENABLE_WLA12
    /*
     * WLA12 algorithm
     */
    ICBFATypeWLA12 = 11,
#endif
#if ENABLE_WLA13
    /*
     * WLA13 algorithm
     */
    ICBFATypeWLA13 = 12,
#endif
#if ENABLE_WLA14
    /*
     * WLA14 algorithm
     */
    ICBFATypeWLA14 = 13,
#endif
#if ENABLE_WLA15
    /*
     * WLA15 algorithm
     */
    ICBFATypeWLA15 = 14,
#endif
#if ENABLE_WLA16
    /*
     * WLA16 algorithm
     */
    ICBFATypeWLA16 = 15,
#endif
#if ENABLE_WLA17
    /*
     * WLA17 algorithm
     */
    ICBFATypeWLA17 = 16,
#endif
#if ENABLE_WLA18
    /*
     * WLA18 algorithm
     */
    ICBFATypeWLA18 = 17,
#endif
#if ENABLE_WLA19
    /*
     * WLA19 algorithm
     */
    ICBFATypeWLA19 = 18,
#endif
#if ENABLE_WLA20
    /*
     * WLA20 algorithm
     */
    ICBFATypeWLA20 = 19,
#endif
#if ENABLE_WLA22
    /*
     * WLA22 algorithm
     */
    ICBFATypeWLA22 = 21,
#endif
#if ENABLE_WLA23
    /*
     * WLA23 algorithm
     */
    ICBFATypeWLA23 = 22,
#endif
#if ENABLE_WLA24
    /*
     * WLA24 algorithm
     */
    ICBFATypeWLA24 = 23,
#endif
#if ENABLE_WLA25
    /*
     * WLA25 algorithm
     */
    ICBFATypeWLA25 = 24,
#endif
#if ENABLE_WLA26
    /*
     * WLA26 algorithm
     */
    ICBFATypeWLA26 = 25,
#endif
#if ENABLE_WLA27
    /*
     * WLA27 algorithm
     */
    ICBFATypeWLA27 = 26,
#endif
#if ENABLE_WLA28
    /*
     * WLA28 algorithm
     */
    ICBFATypeWLA28 = 27,
#endif
#if ENABLE_WLA29
    /*
     * WLA29 algorithm
     */
    ICBFATypeWLA29 = 28,
#endif
#if ENABLE_WLA30
    /*
     * WLA30 algorithm
     */
    ICBFATypeWLA30 = 29,
#endif
#if ENABLE_WLA31
    /*
     * WLA31 algorithm
     */
    ICBFATypeWLA31 = 30,
#endif
#if ENABLE_WLA32
    /*
     * WLA32 algorithm
     */
    ICBFATypeWLA32 = 31,
#endif
#if ENABLE_WLA33
    /*
     * WLA33 algorithm
     */
    ICBFATypeWLA33 = 32,
#endif
#if ENABLE_WLA34
    /*
     * WLA34 algorithm
     */
    ICBFATypeWLA34 = 33,
#endif
#if ENABLE_WLA35
    /*
     * WLA35 algorithm
     */
    ICBFATypeWLA35 = 34,
#endif
#if ENABLE_WLA36
    /*
     * WLA36 algorithm
     */
    ICBFATypeWLA36 = 35,
#endif

#if ENABLE_WLA37
    /*
     * WLA37 algorithm
     */
    ICBFATypeWLA37 = 36,
#endif
    
#if ENABLE_WLA38
    /*
     * WLA38 algorithm
     */
    ICBFATypeWLA38 = 37,
#endif
    
#if ENABLE_WLA39
    /*
     * WLA39 algorithm
     */
    ICBFATypeWLA39 = 38,
#endif
    
#if ENABLE_WLA40
    /*
     * WLA40 algorithm
     */
    ICBFATypeWLA40 = 39,
#endif
    
    
#if ENABLE_WLA1001
    /*
     * WLA1001 algorithm
     */
    ICBFATypeWLA1001 = 1000,
#endif

    ICBFATypeUnknown = 100,
    ICBFATypeRev = 101

} ICBFAType;

/**
 User type
 */
typedef enum : NSUInteger {
    /*
     * Normal person
     */
    ICPeopleTypeNormal,

    /*
     * Athlete
     */
    ICPeopleTypeSportman,
} ICPeopleType;

/**
 Measurement-step data type
 */
typedef enum : NSUInteger {
    /*
     * Weight measurement (ICWeightData)
     */
    ICMeasureStepMeasureWeightData,
    
    /*
     * Balance measurement (ICWeightCenterData)
     */
    ICMeasureStepMeasureCenterData,
    
    /*
     * Impedance measurement starting
     */
    ICMeasureStepAdcStart,

    /*
     * Impedance measurement finished (ICWeightData)
     */
    ICMeasureStepAdcResult,
    
    /*
     * Heart-rate measurement starting
     */
    ICMeasureStepHrStart,
    
    /*
     * Heart-rate measurement finished (ICWeightData)
     */
    ICMeasureStepHrResult,
    
    /*
     * Measurement finished
     */
    ICMeasureStepMeasureOver,

} ICMeasureStep;



/**
 * Rope-skipping mode
 */
typedef enum : NSUInteger {
    /**
     * Free mode
     */
    ICSkipModeFreedom = 0,
    
    /**
     * Timed mode
     */
    ICSkipModeTiming,
    
    /**
     * Counted mode
     */
    ICSkipModeCount,

    /**
     * Timed interval mode
     */
    ICSkipModeInterruptTime,
    
    /**
     * Counted interval mode
     */
    ICSkipModeInterruptCount,

} ICSkipMode;

/**
 * Upgrade status
 */
typedef NS_ENUM(NSUInteger, ICUpgradeStatus) {
    /**
     * Upgrade succeeded
     */
    ICUpgradeStatusSuccess,
    /**
     * Upgrading
     */
    ICUpgradeStatusUpgrading,
    /**
     * Upgrade failed
     */
    ICUpgradeStatusFail,
    /**
     * Upgrade failed: invalid file
     */
    ICUpgradeStatusFailFileInvalid,
    /**
     * Upgrade failed: device does not support upgrade
     */
    ICUpgradeStatusFailNotSupport,
    /**
     * Firmware file downloading (Wi-Fi OTA)
     */
    ICUpgradeStatusFileDownloading,

};


/**
 * Wi-Fi provisioning mode
 */
typedef NS_ENUM(NSUInteger, ICConfigWifiMode) {
    /*
     * Send SSID and password
     */
    ICConfigWifiModeDefault,
    /*
     * Ask the scale to enter provisioning mode (extends the screen-on time)
     */
    ICConfigWifiModeEnter,
    /*
     * Ask the scale to leave provisioning mode
     */
    ICConfigWifiModeExit,
    /*
     * Start scanning for Wi-Fi
     */
    ICConfigWifiModeStartScan,
    /*
     * Stop scanning for Wi-Fi
     */
    ICConfigWifiModeStopScan,
};

/**
 * Wi-Fi provisioning state
 */
typedef NS_ENUM(NSUInteger, ICConfigWifiState) {
    ICConfigWifiStateSuccess,
    ICConfigWifiStateWifiConnecting,
    ICConfigWifiStateServerConnecting,
    ICConfigWifiStateWifiConnectFail,
    ICConfigWifiStateServerConnectFail,
    ICConfigWifiStatePasswordFail,
    ICConfigWifiStateFail,
};

/**
 * Wi-Fi callback-result data type
 */
typedef NS_ENUM(NSUInteger,ICConfigWifiResultType){
    ICConfigWifiResultTypeState,
    ICConfigWifiResultTypeCurrentWifiInfo,
    ICConfigWifiResultTypeScanWifiInfo,
};

/*
 * Rope-skipping light-effect mode
 */
typedef NS_ENUM(NSUInteger, ICSkipLightMode) {
    /*
     * None
     */
    ICSkipLightModeNone,
    /*
     * Speed mode
     */
    ICSkipLightModeRPM,
    /*
     * Timer mode
     */
    ICSkipLightModeTimer,
    /*
     * Count mode
     */
    ICSkipLightModeCount,
    /*
     * Percent mode
     */
    ICSkipLightModePercent,
    /*
     * Trip-rope count mode
     */
    ICSkipLightModeTripRope,
    /*
     * Measurement mode
     */
    ICSkipLightModeMeasuring,
};

/*
 * Voice type
 */
typedef NS_ENUM(NSUInteger, ICSkipSoundType) {
    /*
     * None
     */
    ICSkipSoundTypeNone,
    /*
     * Standard Chinese female voice
     */
    ICSkipSoundTypeFemale,
    /*
     * Standard Chinese male voice
     */
    ICSkipSoundTypeMale,
};

/*
 * Voice mode
 */
typedef NS_ENUM(NSUInteger, ICSkipSoundMode) {
    /*
     * None
     */
    ICSkipSoundModeNone,
    /*
     * By time interval
     */
    ICSkipSoundModeTime,
    /*
     * By count interval
     */
    ICSkipSoundModeCount,
};

/*
 * OTA upgrade mode
 */
typedef NS_ENUM(NSUInteger, ICOTAMode) {
    /*
     * Automatic mode
     */
    ICOTAModeAuto,
    /*
     * Mode 1
     */
    ICOTAMode1,
    /*
     * Mode 2
     */
    ICOTAMode2,
    /*
     * Mode 3
     */
    ICOTAMode3,
    /*
     * Mode 4 (Wi-Fi OTA). Pass the firmware version as the file-path argument
     */
    ICOTAMode4,
};

/*
 * Rope-skipping status
 */

typedef NS_ENUM(NSUInteger, ICSkipStatus) {
    /*
     * Jumping in progress
     */
    ICSkipStatusJumping,
    /*
     * Jumping finished
     */
    ICSkipStatusJumpOver,
    /*
     * Resting between rounds
     */
    ICSkipStatusRest,
};

/*
 * SDK mode
 */

typedef NS_ENUM(NSUInteger, ICSDKMode) {
    /*
     * Default mode
     */
    ICSDKModeDefault,
    /*
     * Competitive mode
     */
    ICSDKModeCompetitive,
};



/*
 * BPM type
 */

typedef NS_ENUM(NSUInteger, ICBPMType) {
    /*
     * default
     */
    ICBPMTypeDefault,

};



/*
 * BMI standard
 */

typedef NS_ENUM(NSUInteger, ICBMIStandard) {
    // WHO
    ICBMIStandard1,
    // Asia
    ICBMIStandard2,
    // Europe
    ICBMIStandard3,
    // ZH_CN
    ICBMIStandard4,
    // ZH_TW
    ICBMIStandard5,
};


typedef NS_ENUM(NSInteger , ICScaleUIItem) {
    /*
    * Weight
    */
    ICScaleUIItemWeight,
    /*
    * BMI
    */
    ICScaleUIItemBMI,
    /*
    * Body-fat percentage
    */
    ICScaleUIItemBodyFatPercent,
    /*
    * Body-water percentage
    */
    ICScaleUIItemMoisturePercent,
    /*
    * Muscle percentage
    */
    ICScaleUIItemMusclePercent,
    /*
    * Bone mass
    */
    ICScaleUIItemBoneMass,
    /*
    * Heart rate
    */
    ICScaleUIItemHR,
    /*
    * Skeletal-muscle percentage
    */
    ICScaleUIItemSmPercent,
    /*
    * Visceral fat
    */
    ICScaleUIItemVisceralFat,
    /*
    * Subcutaneous-fat percentage
    */
    ICScaleUIItemSubcutaneousFatPercent,
    /*
    * Protein percentage
    */
    ICScaleUIItemProteinPercent,
    /*
    * Body type
    */
    ICScaleUIItemBodyType,
    /*
    * Segmental muscle analysis
    */
    ICScaleUIItemStageMuscle,
    /*
    * Segmental fat analysis
    */
    ICScaleUIItemStageFat,
    /*
    * Weight trend
    */
    ICScaleUIItemWeightTrends,
    /*
    * BMI trend
    */
    ICScaleUIItemBMITrends,
    /*
    * Body-fat trend
    */
    ICScaleUIItemBodyFatTrends,
    /*
    * Muscle trend
    */
    ICScaleUIItemMuscleTrends,
    /*
     * Baby-holding screen
     */
    ICScaleUIItemBaby,
    /*
     * Pregnancy screen
     */
    ICScaleUIItemPregnant,

    ICScaleUIItemRev = 32,
};

/*
 * Device-feature support flags
 */

typedef NS_ENUM(NSUInteger, ICDeviceFunction) {
    /*
     * Wi-Fi capability
     */
    ICDeviceFunctionWiFi,
    /*
     * Voice assistant
     */
    ICDeviceFunctionVoiceAssistant,
    /*
     * Sound effects
     */
    ICDeviceFunctionSoundEffect,
    /*
     * Volume
     */
    ICDeviceFunctionVolume,
    /*
     * Voice language
     */
    ICDeviceFunctionVoiceLanguage,
    /*
     * Device uploads body-fat percentage (internal use only)
     */
    ICDeviceFunctionSupportUploadBodyfat,
    /*
     * Weather
     */
    ICDeviceFunctionSupportWeather,
    /*
     * Restart
     */
    ICDeviceFunctionSupportRestart,
    /*
     * Factory reset
     */
    ICDeviceFunctionSupportFactory,

    /*
     * Configure server URL
     */
    ICDeviceFunctionSupportServerUrl,
    /*
     * Support nickname
     */
    ICDeviceFunctionSupportNickName,
    /*
     * Support nickname image
     */
    ICDeviceFunctionSupportNickNameImg,
    /*
     * Support configuring scale UI items
     */
    ICDeviceFunctionSupportSetUIItem,
    /*
     * Support configuring scale lighting
     */
    ICDeviceFunctionSupportScaleLightSetting,
    /*
     * Baby-mode support
     */
    ICDeviceFunctionSupportBabyMode,
    /*
     * Support pushing the height unit
     */
    ICDeviceFunctionSupportHeightUnit,
    /*
     * Support impedance toggle
     */
    ICDeviceFunctionSupportImpedance,
    /*
     * Wi-Fi scanning capability
     */
    ICDeviceFunctionSupportScanWiFi,
    /*
     * Small-object mode support
     */
    ICDeviceFunctionSupportSmartMode,
    /*
     * Battery-level support
     */
    ICDeviceFunctionSupportBattery,

    /*
     * Whether the new user-manager is supported (always 1 on AC2C)
     */
    ICDeviceFunctionSupportNewUserManager,
    /*
     * Support showing UserIndex
     */
    ICDeviceFunctionSupportShowUserIndex,
    /*
     * Support pushing HTTPS certificate
     */
    ICDeviceFunctionSupportHttpsCertificate,
    /*
     * Standby wake-up support
     */
    ICDeviceFunctionSupportWakeUp,
    /*
     * Preset-avatar support
     */
    ICDeviceFunctionSupportAvatar,
 
    /*
     * 8-electrode
     */
    ICDeviceFunctionEightElectrode = 32,
    /*
     * Reserved
     */
    ICDeviceFunctionRev = 33,
};

/**
    Uploaded file type
 */
typedef NS_ENUM(NSUInteger, ICSendDataType) {
    /*
     * Avatar (NSData payload)
     */
    ICSendDataTypeHeadImg,
    /*
     * Nickname (ICUserInfo payload)
     */
    ICSendDataTypeNickName,
    /*
     * Boot animation (NSData payload)
     */
    ICSendDataTypePowerOnImg,
    /*
     * Shutdown animation (NSData payload)
     */
    ICSendDataTypePowerOffImg,
    /*
     * Food icon (NSData payload)
     */
    ICSendDataTypeFoodIcon,
};


/**
 * Body-balance evaluation
 */
typedef NS_ENUM(NSUInteger, ICBodyBalanceEvaluation) {
    /*
     * Not supported
     */
    ICBodyBalanceEvaluationNotSuppport,
    /*
     * Balanced
     */
    ICBodyBalanceEvaluationBalanced,
    /*
     * Slightly unbalanced
     */
    ICBodyBalanceEvaluationSlightlyUnbalanced,
    /*
     * Not balanced
     */
    ICBodyBalanceEvaluationExtremelyUnbalanced,
};

/**
 * Body-fat-scale measurement mode
 */
typedef NS_ENUM(NSUInteger, ICScaleMeasureMode) {
    /**
     * Normal mode
     */
    ICScaleMeasureModeNormal,

    /**
     * Pregnancy mode
     */
    ICScaleMeasureModePregnant,

    /**
     * Baby-holding mode
     */
    ICScaleMeasureModeBaby,
};


#endif /* ICConstant_h */
