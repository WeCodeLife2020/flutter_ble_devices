//
//  VTMDeviceTypeMapper.h
//  flutter_ble_devices
//
//  Maps Viatom BLE advertisement names to (a) a VTProductLib device-type token
//  understood by `VTMURATUtils` and (b) the Android Lepu SDK integer model id
//  so that the Dart layer can treat both platforms uniformly.
//

#import <Foundation/Foundation.h>
#import <VTMProductLib/VTMProductLib.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VTMProtocolPath) {
    VTMProtocolPathUnknown = 0,
    /// Standard 0xA5 header devices driven by VTMURATUtils (ER1/ER2/DuoEK/
    /// VBeat, BP2 family, BP3 family, S1 scale, Lepod/M-series, O2Ring S,
    /// PF-10BWS, BabyO2 patch).
    VTMProtocolPathURAT,
    /// Legacy 0xAA header oximeters (O2Ring, BabyO2, CheckO2, SleepO2,
    /// SleepU, OxyLink, Checkme O2, ...) — driven by VTO2Communicate.
    VTMProtocolPathO2Legacy,
    /// iComon / Welland body-composition scales — driven by ICDeviceManager.
    /// Scanning and connection are handled entirely by ICDeviceManager (not
    /// our CBCentralManager), so mappings with this path are created in
    /// `onScanResult:` rather than `didDiscoverPeripheral:`.
    VTMProtocolPathIComon,
    /// Viatom AirBP / SmartBP blood-pressure monitor — a 0xA5-framed UART
    /// protocol NOT covered by VTProductLib. We talk to the peripheral
    /// directly over Nordic UART (service 6E400001) using `VTAirBPPacket`.
    VTMProtocolPathAirBP,
};

@interface VTMDeviceMapping : NSObject
/// Lepu-compatible integer model id (matches Android `Bluetooth.MODEL_*`).
@property (nonatomic, assign) NSInteger lepuModel;
/// Device family token used by VTMURATUtils category dispatch.
@property (nonatomic, assign) VTMDeviceType vtmDeviceType;
/// Which SDK path to use.
@property (nonatomic, assign) VTMProtocolPath protocolPath;
/// A short family string for Dart consumers: "er1", "er2", "bp2", "bp3",
/// "scale", "woxi", "foxi", "er3", "mseries", "oxy", "baby".
@property (nonatomic, copy) NSString *family;
/// High-level device type: "ecg", "bp", "oximeter", "scale", "baby", "unknown".
@property (nonatomic, copy) NSString *deviceType;
@end

@interface VTMDeviceTypeMapper : NSObject

/// Map a BLE advertised name/localName to a device mapping. Returns nil
/// when the name does not look like a supported Viatom device.
+ (nullable VTMDeviceMapping *)mappingForAdvertisedName:(nullable NSString *)name;

/// Resolve a mapping from the Lepu integer model id (allows the Dart layer
/// to pass the same model id it uses on Android).
+ (nullable VTMDeviceMapping *)mappingForLepuModel:(NSInteger)model;

@end

NS_ASSUME_NONNULL_END
