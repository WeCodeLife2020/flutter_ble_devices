//
//  FlutterBleDevicesPlugin.m
//  flutter_ble_devices
//
//  iOS bridge for Viatom/Lepu BLE medical devices.
//
//  Responsibilities:
//   - Scan / connect BLE peripherals via CoreBluetooth (VTProductLib is a
//     protocol layer and does NOT do its own scanning/connection).
//   - Filter & classify discovered peripherals using VTMDeviceTypeMapper so
//     the Dart layer sees the same `model` integers as the Android plugin.
//   - After connection, hand the CBPeripheral to VTMURATUtils (or
//     VTO2Communicate for legacy 0xAA-header O2Ring devices) and forward
//     commands invoked from the Dart side.
//   - Parse real-time responses with VTMBLEParser / VTO2Parser and emit
//     events on the "viatom_ble_stream" EventChannel using the same schema
//     the Android plugin uses.
//

#import "FlutterBleDevicesPlugin.h"
#import "VTMDeviceTypeMapper.h"
#import "VTAirBPPacket.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <VTMProductLib/VTMProductLib.h>

// Nordic UART service used by the Viatom AirBP / SmartBP.
static NSString *const kAirBPServiceUUID = @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString *const kAirBPTxCharUUID  = @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // phone → device (write)
static NSString *const kAirBPRxCharUUID  = @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // device → phone (notify)

// iComon scale SDK (vendored under ios/Frameworks/).
#import <ICDeviceManager/ICDeviceManager.h>
#import <ICDeviceManager/ICDeviceManagerDelegate.h>
#import <ICDeviceManager/ICScanDeviceDelegate.h>
#import <ICDeviceManager/ICScanDeviceInfo.h>
#import <ICDeviceManager/ICDevice.h>
#import <ICDeviceManager/ICDeviceManagerConfig.h>
#import <ICDeviceManager/ICUserInfo.h>
#import <ICDeviceManager/ICWeightData.h>
#import <ICDeviceManager/ICWeightCenterData.h>
#import <ICDeviceManager/ICConstant.h>

static NSString *const kMethodChannelName = @"viatom_ble";
static NSString *const kEventChannelName  = @"viatom_ble_stream";

#pragma mark - FlutterBleDevicesPlugin

@interface FlutterBleDevicesPlugin () <FlutterStreamHandler,
                                       CBCentralManagerDelegate,
                                       CBPeripheralDelegate,
                                       VTMURATDeviceDelegate,
                                       VTMURATUtilsDelegate,
                                       VTO2CommunicateDelegate,
                                       ICDeviceManagerDelegate,
                                       ICScanDeviceDelegate>

@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel  *eventChannel;
@property (nonatomic, strong) FlutterEventSink      eventSink;

// BLE stack
@property (nonatomic, strong) CBCentralManager *central;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *discovered; // uuidString → peripheral
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *>  *advData;   // uuidString → advertisementData
@property (nonatomic, strong) NSMutableDictionary<NSString *, VTMDeviceMapping *> *mappings; // uuidString → mapping
@property (nonatomic, strong) CBPeripheral *activePeripheral;
@property (nonatomic, strong) VTMDeviceMapping *activeMapping;

// Viatom SDK bridges (only one is active at a time)
@property (nonatomic, strong) VTMURATUtils     *uratUtil;
@property (nonatomic, strong) VTO2Communicate  *o2Util;

// iComon SDK state
@property (nonatomic, assign) BOOL iComonInitialized;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ICScanDeviceInfo *> *iComonScans; // macAddr → scan info
@property (nonatomic, strong) ICDevice *activeIComonDevice;
@property (nonatomic, strong) ICUserInfo *currentUserInfo;

// AirBP state (when activeMapping.protocolPath == VTMProtocolPathAirBP)
@property (nonatomic, strong) CBCharacteristic *airBPTxChar;
@property (nonatomic, strong) CBCharacteristic *airBPRxChar;
@property (nonatomic, strong) NSMutableData    *airBPRxBuffer;

// State
@property (nonatomic, assign) BOOL serviceInitialized;
@property (nonatomic, assign) BOOL serviceDeployed;    // services/chars discovered
@property (nonatomic, assign) NSInteger connectedModel;
@property (nonatomic, strong) NSArray<NSNumber *> *scanModelFilter;
@property (nonatomic, assign) BOOL scanRequested;       // scan requested while central not powered on

// Pending commands
@property (nonatomic, copy)   FlutterResult pendingInitResult;

@end

@implementation FlutterBleDevicesPlugin

#pragma mark - FlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterBleDevicesPlugin *inst = [FlutterBleDevicesPlugin new];
    inst.methodChannel = [FlutterMethodChannel methodChannelWithName:kMethodChannelName
                                                     binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:inst channel:inst.methodChannel];

    inst.eventChannel = [FlutterEventChannel eventChannelWithName:kEventChannelName
                                                  binaryMessenger:[registrar messenger]];
    [inst.eventChannel setStreamHandler:inst];
}

- (instancetype)init {
    if ((self = [super init])) {
        _discovered     = [NSMutableDictionary dictionary];
        _advData        = [NSMutableDictionary dictionary];
        _mappings       = [NSMutableDictionary dictionary];
        _iComonScans    = [NSMutableDictionary dictionary];
        _connectedModel = -1;
        _currentUserInfo = [ICUserInfo new];
        _currentUserInfo.age       = 25;
        _currentUserInfo.height    = 175;
        _currentUserInfo.sex       = ICSexTypeMale;
        _currentUserInfo.peopleType = ICPeopleTypeNormal;
    }
    return self;
}

#pragma mark - FlutterStreamHandler

- (FlutterError *_Nullable)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.eventSink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

- (void)sendEvent:(NSDictionary *)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.eventSink) {
            self.eventSink(event);
        }
    });
}

#pragma mark - MethodChannel dispatch

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *method = call.method;
    if ([method isEqualToString:@"initService"])            { [self handleInitService:result];            return; }
    if ([method isEqualToString:@"isServiceReady"])         { result(@(self.serviceInitialized));         return; }
    if ([method isEqualToString:@"checkPermissions"])       { result(@([self isBluetoothPoweredOn]));     return; }
    if ([method isEqualToString:@"requestPermissions"])     { [self handleRequestPermissions:result];     return; }
    if ([method isEqualToString:@"scan"])                   { [self handleScan:call result:result];       return; }
    if ([method isEqualToString:@"stopScan"])               { [self handleStopScan:result];               return; }
    if ([method isEqualToString:@"connect"])                { [self handleConnect:call result:result];    return; }
    if ([method isEqualToString:@"disconnect"])             { [self handleDisconnect:result];             return; }
    if ([method isEqualToString:@"getConnectedModel"])      { result(@(self.connectedModel));             return; }
    if ([method isEqualToString:@"startMeasurement"])       { [self handleStartMeasurement:call result:result]; return; }
    if ([method isEqualToString:@"stopMeasurement"])        { [self handleStopMeasurement:call result:result];  return; }
    if ([method isEqualToString:@"getDeviceInfo"])          { [self handleGetDeviceInfo:call result:result];    return; }
    if ([method isEqualToString:@"getFileList"])            { [self handleGetFileList:call result:result];      return; }
    if ([method isEqualToString:@"factoryReset"])           { [self handleFactoryReset:call result:result];     return; }
    if ([method isEqualToString:@"updateUserInfo"])         { [self handleUpdateUserInfo:call result:result]; return; }
    result(FlutterMethodNotImplemented);
}

- (void)handleUpdateUserInfo:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSNumber *heightNum = call.arguments[@"height"];
    NSNumber *ageNum    = call.arguments[@"age"];
    NSNumber *isMaleNum = call.arguments[@"isMale"];

    ICUserInfo *info = [ICUserInfo new];
    info.userIndex   = 1;
    info.height      = heightNum ? (NSUInteger)heightNum.doubleValue : 170;
    info.age         = ageNum    ? (NSUInteger)ageNum.integerValue   : 25;
    info.sex         = (isMaleNum == nil || isMaleNum.boolValue) ? ICSexTypeMale : ICSexTypeFemal;
    info.peopleType  = ICPeopleTypeNormal;
    info.enableMeasureImpendence = YES;
    info.enableMeasureHr         = YES;

    self.currentUserInfo = info;
    if (self.iComonInitialized) {
        [[ICDeviceManager shared] updateUserInfo:info];
    }
    result(@YES);
}

#pragma mark - Service lifecycle

- (void)handleInitService:(FlutterResult)result {
    if (self.central == nil) {
        self.central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    // Bring up the iComon SDK exactly once.
    if (!self.iComonInitialized) {
        ICDeviceManagerConfig *cfg = [ICDeviceManagerConfig new];
        cfg.isShowPowerAlert = NO;
        [[ICDeviceManager shared] setDelegate:self];
        [[ICDeviceManager shared] initMgrWithConfig:cfg];
        [[ICDeviceManager shared] updateUserInfo:self.currentUserInfo];
        // iComonInitialized becomes YES once onInitFinish:YES fires.
    }
    self.serviceInitialized = YES;
    [self sendEvent:@{@"event": @"serviceReady"}];
    result(@YES);
}

- (void)handleRequestPermissions:(FlutterResult)result {
    // iOS surfaces the BT usage prompt automatically when CBCentralManager
    // is instantiated; all we can do is nudge creation and report whether
    // Bluetooth is powered on.
    if (self.central == nil) {
        self.central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    result(@([self isBluetoothPoweredOn]));
}

- (BOOL)isBluetoothPoweredOn {
    return self.central != nil && self.central.state == CBManagerStatePoweredOn;
}

#pragma mark - Scan / stop scan

- (void)handleScan:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (!self.serviceInitialized) {
        result([FlutterError errorWithCode:@"NOT_INITIALIZED" message:@"Call initService first" details:nil]);
        return;
    }
    NSArray *models = call.arguments[@"models"];
    self.scanModelFilter = ([models isKindOfClass:NSArray.class]) ? models : nil;

    [self.discovered removeAllObjects];
    [self.advData    removeAllObjects];
    [self.mappings   removeAllObjects];

    if (![self isBluetoothPoweredOn]) {
        // Defer until powered-on via centralManagerDidUpdateState:
        self.scanRequested = YES;
        result(@YES);
        return;
    }
    [self startCentralScan];
    // iComon SDK scans independently via its own CBCentralManager.
    if (self.iComonInitialized) {
        [self.iComonScans removeAllObjects];
        [[ICDeviceManager shared] scanDevice:self];
    }
    result(@YES);
}

- (void)startCentralScan {
    [self.central scanForPeripheralsWithServices:nil
                                         options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
    self.scanRequested = NO;
}

- (void)handleStopScan:(FlutterResult)result {
    if (self.central.isScanning) {
        [self.central stopScan];
    }
    if (self.iComonInitialized) {
        [[ICDeviceManager shared] stopScan];
    }
    self.scanRequested = NO;
    result(@YES);
}

#pragma mark - Connect / disconnect

- (void)handleConnect:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *mac  = call.arguments[@"mac"];
    NSNumber *modelObj = call.arguments[@"model"];
    NSString *sdk  = call.arguments[@"sdk"] ?: @"lepu";

    if ([sdk isEqualToString:@"icomon"]) {
        if (!self.iComonInitialized) {
            result([FlutterError errorWithCode:@"NOT_INITIALIZED"
                                       message:@"iComon SDK not ready — onInitFinish has not fired yet. Retry shortly."
                                       details:nil]);
            return;
        }
        if (mac.length == 0) {
            result([FlutterError errorWithCode:@"INVALID_ARGS" message:@"mac is required" details:nil]);
            return;
        }
        ICDevice *dev = [ICDevice new];
        dev.macAddr = mac;
        self.activeIComonDevice = dev;

        VTMDeviceMapping *mapping = [VTMDeviceMapping new];
        mapping.vtmDeviceType = VTMDeviceTypeUnknown;
        mapping.lepuModel     = -1;
        mapping.protocolPath  = VTMProtocolPathIComon;
        mapping.family        = @"icomon";
        mapping.deviceType    = @"scale";
        self.activeMapping    = mapping;

        [[ICDeviceManager shared] addDevice:dev callback:^(ICDevice * _Nonnull device, ICAddDeviceCallBackCode code) {
            // Connection state update comes through onDeviceConnectionChanged:state:
        }];
        result(@YES);
        return;
    }

    if (mac.length == 0) {
        result([FlutterError errorWithCode:@"INVALID_ARGS" message:@"mac is required" details:nil]);
        return;
    }
    CBPeripheral *peripheral = self.discovered[mac];
    if (peripheral == nil) {
        // Try to recover by identifier lookup in case the device was seen in
        // a prior scan session.
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:mac];
        if (uuid) {
            NSArray *known = [self.central retrievePeripheralsWithIdentifiers:@[uuid]];
            if (known.count > 0) peripheral = known.firstObject;
        }
    }
    if (peripheral == nil) {
        result([FlutterError errorWithCode:@"UNKNOWN_DEVICE"
                                   message:@"Device not discovered — call scan() first"
                                   details:nil]);
        return;
    }

    VTMDeviceMapping *mapping = self.mappings[mac];
    if (mapping == nil && modelObj != nil) {
        mapping = [VTMDeviceTypeMapper mappingForLepuModel:modelObj.integerValue];
    }
    if (mapping == nil) {
        result([FlutterError errorWithCode:@"UNSUPPORTED_DEVICE"
                                   message:@"Device model is not recognised by VTProductLib"
                                   details:nil]);
        return;
    }

    self.activePeripheral = peripheral;
    self.activeMapping    = mapping;
    self.serviceDeployed  = NO;

    // Stop scanning to free the radio for GATT.
    if (self.central.isScanning) [self.central stopScan];

    [self.central connectPeripheral:peripheral options:nil];
    result(@YES);
}

- (void)handleDisconnect:(FlutterResult)result {
    if (self.activeMapping.protocolPath == VTMProtocolPathIComon && self.activeIComonDevice) {
        [[ICDeviceManager shared] removeDevice:self.activeIComonDevice
                                      callback:^(ICDevice * _Nonnull device, ICRemoveDeviceCallBackCode code) {}];
        self.activeIComonDevice = nil;
    } else if (self.activePeripheral) {
        [self.central cancelPeripheralConnection:self.activePeripheral];
    }
    // Tear down Viatom utils
    self.uratUtil = nil;
    self.o2Util   = nil;
    self.connectedModel = -1;
    self.serviceDeployed = NO;
    result(@YES);
}

#pragma mark - Measurement / info / file list / factory reset

- (void)handleStartMeasurement:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (![self ensureReady:result]) return;
    VTMDeviceMapping *m = self.activeMapping;
    if (m.protocolPath == VTMProtocolPathIComon) {
        // iComon scales stream weight data automatically after connection —
        // no explicit start command is required.
        result(@YES);
        return;
    }
    if (m.protocolPath == VTMProtocolPathAirBP) {
        [self writeAirBPCommand:VTAirBPCmdStartMeasure payload:nil];
        result(@YES);
        return;
    }
    if (m.protocolPath == VTMProtocolPathO2Legacy) {
        [self.o2Util beginGetRealData];
        [self.o2Util beginGetRealWave];
    } else {
        switch (m.vtmDeviceType) {
            case VTMDeviceTypeECG:
                [self.uratUtil requestECGRealData];
                break;
            case VTMDeviceTypeBP:
                [self.uratUtil requestBPRealData];
                break;
            case VTMDeviceTypeScale:
                [self.uratUtil requestScaleRealData];
                [self.uratUtil requestScaleRealWve];
                break;
            case VTMDeviceTypeER3:
                [self.uratUtil requestER3ECGRealData];
                break;
            case VTMDeviceTypeMSeries:
                [self.uratUtil requestMSeriesRunParamsWithIndex:0];
                break;
            case VTMDeviceTypeWOxi:
                [self.uratUtil woxi_requestWOxiRealData];
                [self.uratUtil observeParameters:YES waveform:YES rawdata:NO accdata:NO];
                break;
            case VTMDeviceTypeFOxi:
                [self.uratUtil foxi_makeInfoSend:YES];
                [self.uratUtil foxi_makeWaveSend:YES];
                break;
            case VTMDeviceTypeBabyPatch:
                [self.uratUtil baby_requestRunParams];
                break;
            default:
                break;
        }
    }
    result(@YES);
}

- (void)handleStopMeasurement:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (![self ensureReady:result]) return;
    VTMDeviceMapping *m = self.activeMapping;
    if (m.protocolPath == VTMProtocolPathIComon) {
        result(@YES);
        return;
    }
    if (m.protocolPath == VTMProtocolPathAirBP) {
        [self writeAirBPCommand:VTAirBPCmdStopMeasure payload:nil];
        result(@YES);
        return;
    }
    if (m.protocolPath == VTMProtocolPathO2Legacy) {
        // VTO2Communicate has no explicit stop-real-time; stop pushing by
        // disconnecting observation is handled implicitly on disconnect.
    } else if (m.vtmDeviceType == VTMDeviceTypeWOxi) {
        [self.uratUtil observeParameters:NO waveform:NO rawdata:NO accdata:NO];
    } else if (m.vtmDeviceType == VTMDeviceTypeFOxi) {
        [self.uratUtil foxi_makeInfoSend:NO];
        [self.uratUtil foxi_makeWaveSend:NO];
    } else if (m.vtmDeviceType == VTMDeviceTypeECG) {
        [self.uratUtil exitER1MeasurementMode];
    } else if (m.vtmDeviceType == VTMDeviceTypeER3) {
        [self.uratUtil exitER3MeasurementMode];
    }
    result(@YES);
}

- (void)handleGetDeviceInfo:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (![self ensureReady:result]) return;
    VTMDeviceMapping *m = self.activeMapping;
    if (m.protocolPath == VTMProtocolPathIComon) {
        // Device info for iComon scales arrives via onReceiveDeviceInfo: — no
        // explicit request API exists in this SDK version.
        result(@YES);
        return;
    }
    if (m.protocolPath == VTMProtocolPathAirBP) {
        [self writeAirBPCommand:VTAirBPCmdGetInfo payload:nil];
        result(@YES);
        return;
    }
    if (m.protocolPath == VTMProtocolPathO2Legacy) {
        [self.o2Util beginGetInfo];
    } else {
        [self.uratUtil requestDeviceInfo];
    }
    result(@YES);
}

- (void)handleGetFileList:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (![self ensureReady:result]) return;
    VTMDeviceMapping *m = self.activeMapping;
    if (m.protocolPath == VTMProtocolPathIComon) {
        result([FlutterError errorWithCode:@"UNSUPPORTED"
                                   message:@"iComon scales do not expose a file list API."
                                   details:nil]);
        return;
    }
    if (m.protocolPath == VTMProtocolPathAirBP) {
        result([FlutterError errorWithCode:@"UNSUPPORTED"
                                   message:@"AirBP historical-record browsing is not wired yet."
                                   details:nil]);
        return;
    }
    if (m.protocolPath == VTMProtocolPathO2Legacy) {
        result([FlutterError errorWithCode:@"UNSUPPORTED"
                                   message:@"File list on legacy O2 path uses prepareReadFile; not yet wired."
                                   details:nil]);
        return;
    }
    [self.uratUtil requestFilelist];
    result(@YES);
}

- (void)handleFactoryReset:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (![self ensureReady:result]) return;
    VTMDeviceMapping *m = self.activeMapping;
    if (m.protocolPath == VTMProtocolPathIComon) {
        result([FlutterError errorWithCode:@"UNSUPPORTED"
                                   message:@"Factory reset is not exposed by the iComon SDK."
                                   details:nil]);
        return;
    }
    if (m.protocolPath == VTMProtocolPathAirBP) {
        result([FlutterError errorWithCode:@"UNSUPPORTED"
                                   message:@"Factory reset is not exposed by the AirBP protocol wrapper."
                                   details:nil]);
        return;
    }
    if (m.protocolPath == VTMProtocolPathO2Legacy) {
        [self.o2Util beginFactory];
    } else {
        [self.uratUtil factoryReset];
    }
    result(@YES);
}

- (BOOL)ensureReady:(FlutterResult)result {
    // A connection is ready when we have a mapping AND the underlying SDK
    // has reported that services are up. For iComon scales there is no
    // Lepu model id, so `connectedModel` is allowed to stay -1.
    if (self.activeMapping == nil || !self.serviceDeployed) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED"
                                   message:@"No device connected / services not deployed yet"
                                   details:nil]);
        return NO;
    }
    return YES;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        if (self.scanRequested) {
            [self startCentralScan];
        }
    } else {
        // Surface disconnect when bluetooth goes away.
        if (self.activePeripheral) {
            [self sendEvent:@{@"event": @"connectionState",
                              @"state": @"disconnected",
                              @"reason": @"bluetooth_off"}];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *, id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    NSString *name = advertisementData[CBAdvertisementDataLocalNameKey];
    if (name.length == 0) name = peripheral.name;
    VTMDeviceMapping *mapping = [VTMDeviceTypeMapper mappingForAdvertisedName:name];
    if (mapping == nil) return;  // Not a Viatom device we recognise.

    // Honour scan model filter when provided.
    if (self.scanModelFilter.count > 0 &&
        ![self.scanModelFilter containsObject:@(mapping.lepuModel)]) {
        return;
    }

    NSString *uuid = peripheral.identifier.UUIDString;
    self.discovered[uuid] = peripheral;
    self.advData[uuid]    = advertisementData;
    self.mappings[uuid]   = mapping;

    NSString *sdkLabel = (mapping.protocolPath == VTMProtocolPathAirBP) ? @"airbp" : @"lepu";
    [self sendEvent:@{@"event": @"deviceFound",
                      @"name":  name ?: @"",
                      @"mac":   uuid,
                      @"model": @(mapping.lepuModel),
                      @"rssi":  RSSI ?: @0,
                      @"sdk":   sdkLabel,
                      @"deviceType": mapping.deviceType,
                      @"family": mapping.family}];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    VTMDeviceMapping *m = self.activeMapping;
    if (m == nil) m = self.mappings[peripheral.identifier.UUIDString];
    if (m.protocolPath == VTMProtocolPathAirBP) {
        // Drive the peripheral ourselves — no VT/VTM util is involved.
        self.uratUtil = nil;
        self.o2Util   = nil;
        self.airBPRxBuffer = [NSMutableData data];
        [peripheral discoverServices:@[[CBUUID UUIDWithString:kAirBPServiceUUID]]];
        return;
    }
    if (m.protocolPath == VTMProtocolPathO2Legacy) {
        VTO2Communicate *util = [VTO2Communicate new];
        util.o2Delegate = self;
        util.delegate   = self;
        util.deviceDelegate = self;
        [util setPeripheral:peripheral advertisementData:self.advData[peripheral.identifier.UUIDString]];
        self.o2Util = util;
        self.uratUtil = nil;
    } else {
        VTMURATUtils *util = [VTMURATUtils new];
        util.delegate = self;
        util.deviceDelegate = self;
        [util setPeripheral:peripheral advertisementData:self.advData[peripheral.identifier.UUIDString]];
        self.uratUtil = util;
        self.o2Util = nil;
    }
    // We do NOT yet emit "connected" — we wait for service-deployed callback.
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    self.activePeripheral = nil;
    self.activeMapping    = nil;
    self.connectedModel   = -1;
    self.serviceDeployed  = NO;
    [self sendEvent:@{@"event": @"connectionState",
                      @"state": @"disconnected",
                      @"reason": error.localizedDescription ?: @"connect_failed"}];
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    self.activePeripheral = nil;
    self.activeMapping    = nil;
    self.connectedModel   = -1;
    self.serviceDeployed  = NO;
    self.uratUtil         = nil;
    self.o2Util           = nil;
    self.airBPTxChar      = nil;
    self.airBPRxChar      = nil;
    self.airBPRxBuffer    = nil;
    [self sendEvent:@{@"event": @"connectionState",
                      @"state": @"disconnected",
                      @"reason": error.localizedDescription ?: @"user_initiated"}];
}

#pragma mark - VTMURATDeviceDelegate  (URAT / WOxi / FOxi / ...)

- (void)utilDeployCompletion:(VTMURATUtils *)util {
    self.serviceDeployed = YES;
    self.connectedModel  = self.activeMapping.lepuModel;
    [self sendEvent:@{@"event": @"connectionState",
                      @"state": @"connected",
                      @"model": @(self.connectedModel),
                      @"family": self.activeMapping.family,
                      @"deviceType": self.activeMapping.deviceType}];
}

- (void)utilDeployFailed:(VTMURATUtils *)util {
    [self sendEvent:@{@"event": @"connectionState",
                      @"state": @"disconnected",
                      @"reason": @"service_discovery_failed"}];
}

- (void)util:(VTMURATUtils *)util updateDeviceRSSI:(NSNumber *)RSSI {
    [self sendEvent:@{@"event": @"rssi", @"rssi": RSSI ?: @0}];
}

#pragma mark - VTMURATUtilsDelegate  (response dispatcher)

- (void)util:(VTMURATUtils *)util
commandSendFailed:(u_char)errorCode {
    [self sendEvent:@{@"event": @"commandError", @"errorCode": @(errorCode)}];
}

- (void)util:(VTMURATUtils *)util
commandFailed:(u_char)cmdType
  deviceType:(VTMDeviceType)deviceType
  failedType:(VTMBLEPkgType)type {
    [self sendEvent:@{@"event": @"commandError",
                      @"cmdType": @(cmdType),
                      @"deviceType": @(deviceType),
                      @"failedType": @(type)}];
}

- (void)util:(VTMURATUtils *)util
commandCompletion:(u_char)cmdType
   deviceType:(VTMDeviceType)deviceType
     response:(NSData *)response {
    if (response == nil) return;
    [self dispatchURATResponse:response cmdType:cmdType deviceType:deviceType];
}

- (void)receiveHeartRateByStandardService:(Byte)hrByte {
    [self sendEvent:@{@"event": @"rtData",
                      @"deviceType": self.activeMapping.deviceType ?: @"unknown",
                      @"deviceFamily": self.activeMapping.family   ?: @"unknown",
                      @"model": @(self.connectedModel),
                      @"hr": @(hrByte)}];
}

#pragma mark - URAT response parsing

- (void)dispatchURATResponse:(NSData *)response
                     cmdType:(u_char)cmdType
                  deviceType:(VTMDeviceType)deviceType {
    // Common commands (battery, device info, file list) — cmdType uses
    // VTMBLECmd values.
    if (cmdType == VTMBLECmdGetDeviceInfo) {
        VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
        [self sendEvent:@{@"event": @"deviceInfo",
                          @"model": @(self.connectedModel),
                          @"hw_version": @(info.hw_version),
                          @"fw_version": @(info.fw_version),
                          @"bl_version": @(info.bl_version),
                          @"device_type": @(info.device_type),
                          @"protocol_version": @(info.protocol_version),
                          @"raw": [response base64EncodedStringWithOptions:0]}];
        return;
    }
    if (cmdType == VTMBLECmdGetBattery) {
        VTMBatteryInfo bi = [VTMBLEParser parseBatteryInfo:response];
        [self sendEvent:@{@"event": @"battery",
                          @"state": @(bi.state),
                          @"percent": @(bi.percent),
                          @"voltage": @(bi.voltage)}];
        return;
    }
    if (cmdType == VTMBLECmdGetFileList) {
        VTMFileList list = [VTMBLEParser parseFileList:response];
        NSMutableArray *files = [NSMutableArray array];
        for (int i = 0; i < list.file_num; i++) {
            NSString *fn = [[NSString alloc] initWithBytes:list.fileName[i].str
                                                    length:sizeof(list.fileName[i].str)
                                                  encoding:NSUTF8StringEncoding];
            if (fn.length) [files addObject:[fn stringByTrimmingCharactersInSet:
                                             [NSCharacterSet controlCharacterSet]]];
        }
        [self sendEvent:@{@"event": @"fileList",
                          @"model": @(self.connectedModel),
                          @"files": files}];
        return;
    }
    if (cmdType == VTMBLECmdSyncTime) {
        [self sendEvent:@{@"event": @"connectionState",
                          @"state": @"connected",
                          @"model": @(self.connectedModel),
                          @"subEvent": @"setTime"}];
        return;
    }

    // Device-type specific parsing
    switch (deviceType) {
        case VTMDeviceTypeECG:
            [self parseECGResponse:response cmdType:cmdType]; break;
        case VTMDeviceTypeBP:
            [self parseBPResponse:response cmdType:cmdType];  break;
        case VTMDeviceTypeScale:
            [self parseScaleResponse:response cmdType:cmdType]; break;
        case VTMDeviceTypeWOxi:
            [self parseWOxiResponse:response cmdType:cmdType]; break;
        case VTMDeviceTypeFOxi:
            [self parseFOxiResponse:response cmdType:cmdType]; break;
        case VTMDeviceTypeER3:
        case VTMDeviceTypeMSeries:
            [self parseER3Response:response cmdType:cmdType];  break;
        case VTMDeviceTypeBabyPatch:
            [self parseBabyResponse:response cmdType:cmdType]; break;
        default:
            // Unknown — emit raw for debugging.
            [self sendEvent:@{@"event": @"raw",
                              @"cmdType": @(cmdType),
                              @"deviceType": @(deviceType),
                              @"data": [response base64EncodedStringWithOptions:0]}];
            break;
    }
}

- (void)parseECGResponse:(NSData *)response cmdType:(u_char)cmdType {
    if (cmdType == VTMECGCmdGetRealData) {
        VTMRealTimeData rt = [VTMBLEParser parseRealTimeData:response];
        VTMFlagDetail flag = [VTMBLEParser parseFlag:rt.run_para.sys_flag];
        VTMRunStatus  st   = [VTMBLEParser parseStatus:rt.run_para.run_status];
        NSMutableArray *mv = [NSMutableArray arrayWithCapacity:rt.waveform.sampling_num];
        NSMutableArray *raw = [NSMutableArray arrayWithCapacity:rt.waveform.sampling_num];
        for (int i = 0; i < rt.waveform.sampling_num && i < 300; i++) {
            short s = rt.waveform.wave_data[i];
            [raw addObject:@(s)];
            [mv  addObject:@([VTMBLEParser mVFromShort:s])];
        }
        [self sendEvent:@{@"event": @"rtData",
                          @"deviceType": @"ecg",
                          @"deviceFamily": self.activeMapping.family ?: @"er1",
                          @"model": @(self.connectedModel),
                          @"hr": @(rt.run_para.hr),
                          @"battery": @(rt.run_para.percent),
                          @"batteryState": @(flag.batteryStatus),
                          @"recordTime": @(rt.run_para.record_time),
                          @"curStatus": @(st.curStatus),
                          @"isLeadOff": @(flag.rMark == 0 && st.curStatus == 0),
                          @"ecgFloats": mv,
                          @"ecgShorts": raw,
                          @"samplingRate": @125,
                          @"mvConversion": @0.002467}];
        return;
    }
    if (cmdType == VTMECGCmdGetRealWave) {
        VTMRealTimeWF wf = [VTMBLEParser parseRealTimeWaveform:response];
        NSMutableArray *mv = [NSMutableArray arrayWithCapacity:wf.sampling_num];
        for (int i = 0; i < wf.sampling_num && i < 300; i++) {
            [mv addObject:@([VTMBLEParser mVFromShort:wf.wave_data[i]])];
        }
        [self sendEvent:@{@"event": @"rtWaveform",
                          @"deviceType": @"ecg",
                          @"deviceFamily": self.activeMapping.family ?: @"er1",
                          @"model": @(self.connectedModel),
                          @"waveType": @"ecg",
                          @"ecgFloats": mv,
                          @"samplingRate": @125,
                          @"mvConversion": @0.002467}];
        return;
    }
    [self emitRaw:response cmd:cmdType dev:VTMDeviceTypeECG];
}

- (void)parseBPResponse:(NSData *)response cmdType:(u_char)cmdType {
    // VTProductLib 2.0 introduced BP2 RT parsing but does NOT expose a
    // public C-struct parser in the xcframework headers we have. We surface
    // base64 bytes so the Dart layer can decode if desired and also derive
    // a best-effort status byte. Users needing rich BP2 RT data should file
    // a PR to parse the protocol here.
    if (cmdType == VTMBPCmdGetRealData || cmdType == VTMBPCmdGetRealPressure ||
        cmdType == VTMBPCmdGetRealStatus) {
        NSString *measureType = (cmdType == VTMBPCmdGetRealPressure) ? @"bp_measuring"
                              : (cmdType == VTMBPCmdGetRealStatus)   ? @"status"
                              :                                         @"bp_result";
        [self sendEvent:@{@"event": @"rtData",
                          @"deviceType": @"bp",
                          @"deviceFamily": self.activeMapping.family ?: @"bp2",
                          @"model": @(self.connectedModel),
                          @"measureType": measureType,
                          @"raw": [response base64EncodedStringWithOptions:0]}];
        return;
    }
    if (cmdType == VTMBPCmdGetConfig) {
        [self sendEvent:@{@"event": @"deviceConfig",
                          @"family": self.activeMapping.family ?: @"bp2",
                          @"raw": [response base64EncodedStringWithOptions:0]}];
        return;
    }
    [self emitRaw:response cmd:cmdType dev:VTMDeviceTypeBP];
}

- (void)parseScaleResponse:(NSData *)response cmdType:(u_char)cmdType {
    NSString *sub = (cmdType == VTMSCALECmdGetRealWave)  ? @"wave"
                  : (cmdType == VTMSCALECmdGetRealData)  ? @"data"
                  : (cmdType == VTMSCALECmdGetRunParams) ? @"run"
                  :                                        @"config";
    [self sendEvent:@{@"event": [sub isEqualToString:@"wave"] ? @"rtWaveform" : @"rtData",
                      @"deviceType": @"scale",
                      @"deviceFamily": @"s1",
                      @"model": @(self.connectedModel),
                      @"subType": sub,
                      @"raw": [response base64EncodedStringWithOptions:0]}];
}

- (void)parseWOxiResponse:(NSData *)response cmdType:(u_char)cmdType {
    NSString *sub = @"unknown";
    switch (cmdType) {
        case VTMWOxiCmdGetRunParams:   sub = @"runParams"; break;
        case VTMWOxiCmdGetRealData:    sub = @"real";      break;
        case VTMWOxiCmdGetRawdata:     sub = @"raw";       break;
        case VTMWOxiCmdPushRunParams:  sub = @"pushParams"; break;
        case VTMWOxiCmdPushRealWave:   sub = @"pushWave"; break;
        case VTMWOxiCmdPushRawData:    sub = @"pushRaw";  break;
        default: break;
    }
    NSString *evt = ([sub isEqualToString:@"pushWave"] || [sub isEqualToString:@"raw"] ||
                     [sub isEqualToString:@"pushRaw"]) ? @"rtWaveform" : @"rtData";
    [self sendEvent:@{@"event": evt,
                      @"deviceType": @"oximeter",
                      @"deviceFamily": @"woxi",
                      @"model": @(self.connectedModel),
                      @"subType": sub,
                      @"raw": [response base64EncodedStringWithOptions:0]}];
}

- (void)parseFOxiResponse:(NSData *)response cmdType:(u_char)cmdType {
    NSString *sub = @"unknown";
    switch (cmdType) {
        case VTMFOxiCmdInfoResp: sub = @"info"; break;
        case VTMFOxiCmdWaveResp: sub = @"wave"; break;
        case VTMFOxiCmdGetConfig: sub = @"config"; break;
        default: break;
    }
    NSString *evt = [sub isEqualToString:@"wave"] ? @"rtWaveform" : @"rtData";
    [self sendEvent:@{@"event": evt,
                      @"deviceType": @"oximeter",
                      @"deviceFamily": @"foxi",
                      @"model": @(self.connectedModel),
                      @"subType": sub,
                      @"raw": [response base64EncodedStringWithOptions:0]}];
}

- (void)parseER3Response:(NSData *)response cmdType:(u_char)cmdType {
    NSString *sub = (cmdType == VTMER3ECGCmdGetRealData)    ? @"er3Real"
                  : (cmdType == VTMMSeriesCmdGetRealData)   ? @"mSeriesRun"
                  :                                            @"config";
    [self sendEvent:@{@"event": @"rtData",
                      @"deviceType": @"ecg",
                      @"deviceFamily": self.activeMapping.family ?: @"er3",
                      @"model": @(self.connectedModel),
                      @"subType": sub,
                      @"raw": [response base64EncodedStringWithOptions:0]}];
}

- (void)parseBabyResponse:(NSData *)response cmdType:(u_char)cmdType {
    NSString *sub = (cmdType == VTMBabyCmdGetRunParams) ? @"runParams"
                  : (cmdType == VTMBabyCmdGetGesture)   ? @"gesture"
                  :                                        @"config";
    [self sendEvent:@{@"event": @"rtData",
                      @"deviceType": @"baby",
                      @"deviceFamily": @"baby",
                      @"model": @(self.connectedModel),
                      @"subType": sub,
                      @"raw": [response base64EncodedStringWithOptions:0]}];
}

- (void)emitRaw:(NSData *)response cmd:(u_char)cmd dev:(VTMDeviceType)dev {
    [self sendEvent:@{@"event": @"raw",
                      @"cmdType": @(cmd),
                      @"deviceType": @(dev),
                      @"data": [response base64EncodedStringWithOptions:0]}];
}

#pragma mark - VTO2CommunicateDelegate  (legacy 0xAA O2Ring path)

- (void)o2_serviceDeployed:(BOOL)completed {
    if (completed) {
        self.serviceDeployed = YES;
        self.connectedModel  = self.activeMapping.lepuModel;
        [self sendEvent:@{@"event": @"connectionState",
                          @"state": @"connected",
                          @"model": @(self.connectedModel),
                          @"family": self.activeMapping.family ?: @"oxy",
                          @"deviceType": @"oximeter"}];
    } else {
        [self sendEvent:@{@"event": @"connectionState",
                          @"state": @"disconnected",
                          @"reason": @"service_discovery_failed"}];
    }
}

- (void)writeDataErrorCode:(int)errorCode {
    [self sendEvent:@{@"event": @"commandError", @"errorCode": @(errorCode)}];
}

- (void)commonResponse:(VTCmd)cmdType andResult:(VTCommonResult)result {
    [self sendEvent:@{@"event": @"commandAck",
                      @"cmdType": @(cmdType),
                      @"result": @(result)}];
}

- (void)getInfoWithResultData:(NSData *)infoData {
    if (infoData == nil) return;
    VTO2Info *info = [VTO2Parser parseO2InfoWithData:infoData];
    NSMutableDictionary *payload = [@{@"event": @"deviceInfo",
                                      @"model": @(self.connectedModel),
                                      @"deviceType": @"oximeter",
                                      @"family": self.activeMapping.family ?: @"oxy"} mutableCopy];
    if (info.hardware)   payload[@"hwVersion"] = info.hardware;
    if (info.software)   payload[@"fwVersion"] = info.software;
    if (info.sn)         payload[@"sn"]        = info.sn;
    if (info.branchCode) payload[@"branchCode"] = info.branchCode;
    if (info.curBattery) payload[@"battery"]   = info.curBattery;
    [self sendEvent:payload];
}

- (void)realDataCallBackWithData:(NSData *)realData {
    if (realData == nil) return;
    VTRealObject *obj = [VTO2Parser parseO2RealObjectWithData:realData];
    [self sendEvent:@{@"event": @"rtData",
                      @"deviceType": @"oximeter",
                      @"deviceFamily": self.activeMapping.family ?: @"oxy",
                      @"model": @(self.connectedModel),
                      @"spo2": @(obj.spo2),
                      @"pr": @(obj.hr),
                      @"pi": @(obj.pi),
                      @"battery": @(obj.battery),
                      @"batteryState": @(obj.batState),
                      @"state": @(obj.leadState),
                      @"vector": @(obj.vector)}];
}

- (void)realWaveCallBackWithData:(NSData *)realWave {
    if (realWave == nil) return;
    VTRealWave *wave = [VTO2Parser parseO2RealWaveWithData:realWave];
    NSMutableArray *ints = [NSMutableArray arrayWithCapacity:wave.points.count];
    for (NSNumber *n in wave.points) [ints addObject:n];
    [self sendEvent:@{@"event": @"rtWaveform",
                      @"deviceType": @"oximeter",
                      @"deviceFamily": self.activeMapping.family ?: @"oxy",
                      @"model": @(self.connectedModel),
                      @"spo2": @(wave.spo2),
                      @"pr": @(wave.hr),
                      @"pi": @(wave.pi),
                      @"waveData": ints}];
}

- (void)realPPGCallBackWithData:(NSData *)realPPG {
    if (realPPG == nil) return;
    NSArray<VTRealPPG *> *ppgs = [VTO2Parser parseO2RealPPGWithData:realPPG];
    NSMutableArray *ir = [NSMutableArray arrayWithCapacity:ppgs.count];
    NSMutableArray *red = [NSMutableArray arrayWithCapacity:ppgs.count];
    for (VTRealPPG *p in ppgs) {
        [ir addObject:@(p.ir)];
        [red addObject:@(p.red)];
    }
    [self sendEvent:@{@"event": @"rtWaveform",
                      @"deviceType": @"oximeter",
                      @"deviceFamily": self.activeMapping.family ?: @"oxy",
                      @"model": @(self.connectedModel),
                      @"waveType": @"ppg",
                      @"ir":  ir,
                      @"red": red}];
}

- (void)updatePeripheralRSSI:(NSNumber *)RSSI {
    [self sendEvent:@{@"event": @"rssi", @"rssi": RSSI ?: @0}];
}

- (void)postCurrentReadProgress:(double)progress {
    [self sendEvent:@{@"event": @"readProgress", @"progress": @(progress)}];
}

- (void)readCompleteWithData:(VTFileToRead *)fileData {
    [self sendEvent:@{@"event": @"readComplete",
                      @"fileName": fileData.fileName ?: @"",
                      @"size": @(fileData.fileSize),
                      @"totalPkgNum": @(fileData.totalPkgNum)}];
}

#pragma mark - ICDeviceManagerDelegate  (iComon scale path)

- (void)onInitFinish:(BOOL)bSuccess {
    self.iComonInitialized = bSuccess;
}

- (void)onBleState:(ICBleState)state {
    // Surface as a simple informational event — iComon's BLE state is tracked
    // separately from our CBCentralManager instance.
    [self sendEvent:@{@"event": @"icomonBleState", @"state": @(state)}];
}

- (void)onDeviceConnectionChanged:(ICDevice *)device state:(ICDeviceConnectState)state {
    if (device == nil) return;
    if (state == ICDeviceConnectStateConnected) {
        self.serviceDeployed = YES;
        [self sendEvent:@{@"event": @"connectionState",
                          @"state":  @"connected",
                          @"mac":    device.macAddr ?: @"",
                          @"sdk":    @"icomon",
                          @"family": @"icomon",
                          @"deviceType": @"scale"}];
    } else {
        self.serviceDeployed = NO;
        if ([device.macAddr isEqualToString:self.activeIComonDevice.macAddr]) {
            self.activeIComonDevice = nil;
            if (self.activeMapping.protocolPath == VTMProtocolPathIComon) {
                self.activeMapping = nil;
            }
        }
        [self sendEvent:@{@"event": @"connectionState",
                          @"state":  @"disconnected",
                          @"mac":    device.macAddr ?: @"",
                          @"sdk":    @"icomon",
                          @"reason": @"device_disconnected"}];
    }
}

- (void)onReceiveWeightData:(ICDevice *)device data:(ICWeightData *)data {
    [self emitIComonWeight:data device:device];
}

- (void)onReceiveMeasureStepData:(ICDevice *)device step:(ICMeasureStep)step data:(NSObject *)data {
    if (device == nil || data == nil) return;
    switch (step) {
        case ICMeasureStepMeasureWeightData: {
            if ([data isKindOfClass:[ICWeightData class]]) {
                [self emitIComonWeight:(ICWeightData *)data device:device];
            }
            break;
        }
        case ICMeasureStepMeasureCenterData: {
            if ([data isKindOfClass:[ICWeightCenterData class]]) {
                ICWeightCenterData *c = (ICWeightCenterData *)data;
                [self sendEvent:@{@"event": @"rtData",
                                  @"deviceType": @"scale",
                                  @"deviceFamily": @"icomon",
                                  @"mac": device.macAddr ?: @"",
                                  @"sdk": @"icomon",
                                  @"isStabilized": @(c.isStabilized),
                                  @"leftPercent":  @(c.leftPercent),
                                  @"rightPercent": @(c.rightPercent)}];
            }
            break;
        }
        case ICMeasureStepHrResult: {
            if ([data isKindOfClass:[ICWeightData class]]) {
                ICWeightData *w = (ICWeightData *)data;
                [self sendEvent:@{@"event": @"rtData",
                                  @"deviceType": @"scale",
                                  @"deviceFamily": @"icomon",
                                  @"mac": device.macAddr ?: @"",
                                  @"sdk": @"icomon",
                                  @"hr":  @(w.hr),
                                  @"step": @"ICMeasureStepHrResult"}];
            }
            break;
        }
        case ICMeasureStepMeasureOver: {
            if ([data isKindOfClass:[ICWeightData class]]) {
                ICWeightData *w = (ICWeightData *)data;
                w.isStabilized = YES;
                [self emitIComonWeight:w device:device];
            }
            break;
        }
        default:
            break;
    }
}

- (void)onReceiveHR:(ICDevice *)device hr:(int)hr {
    [self sendEvent:@{@"event": @"rtData",
                      @"deviceType": @"scale",
                      @"deviceFamily": @"icomon",
                      @"mac": device.macAddr ?: @"",
                      @"sdk": @"icomon",
                      @"hr":  @(hr)}];
}

- (void)onReceiveBattery:(ICDevice *)device battery:(NSUInteger)battery ext:(NSObject *)ext {
    [self sendEvent:@{@"event": @"battery",
                      @"mac": device.macAddr ?: @"",
                      @"sdk": @"icomon",
                      @"percent": @(battery)}];
}

- (void)onReceiveRSSI:(ICDevice *)device rssi:(int)rssi {
    [self sendEvent:@{@"event": @"rssi",
                      @"mac":  device.macAddr ?: @"",
                      @"sdk":  @"icomon",
                      @"rssi": @(rssi)}];
}

#pragma mark - ICScanDeviceDelegate

- (void)onScanResult:(ICScanDeviceInfo *)deviceInfo {
    if (deviceInfo == nil || deviceInfo.macAddr.length == 0) return;
    self.iComonScans[deviceInfo.macAddr] = deviceInfo;
    [self sendEvent:@{@"event":      @"deviceFound",
                      @"name":       deviceInfo.name ?: @"",
                      @"mac":        deviceInfo.macAddr,
                      @"model":      @(-1),
                      @"rssi":       @(deviceInfo.rssi),
                      @"sdk":        @"icomon",
                      @"deviceType": @"scale",
                      @"family":     @"icomon",
                      @"icDeviceType": @(deviceInfo.type),
                      @"icSubType":    @(deviceInfo.subType)}];
}

#pragma mark - iComon helpers

- (void)emitIComonWeight:(ICWeightData *)data device:(ICDevice *)device {
    if (data == nil || device == nil) return;
    double w = data.weight_kg;
    double (^r1)(double) = ^double(double v) { return round(v * 10.0) / 10.0; };
    double (^r2)(double) = ^double(double v) { return round(v * 100.0) / 100.0; };
    double muscleKg         = r1((double)data.musclePercent / 100.0 * w);
    double skeletalMuscleKg = r1((double)data.smPercent / 100.0 * w);
    double fatMassKg        = r1((double)data.bodyFatPercent / 100.0 * w);

    [self sendEvent:@{@"event": @"rtData",
                      @"deviceType":            @"scale",
                      @"deviceFamily":          @"icomon",
                      @"mac":                   device.macAddr ?: @"",
                      @"sdk":                   @"icomon",
                      @"isLocked":              @(data.isStabilized),
                      @"weightKg":              @(r2(w)),
                      @"bmi":                   @(r1(data.bmi)),
                      @"fat":                   @(r1(data.bodyFatPercent)),
                      @"fat_mass":              @(fatMassKg),
                      @"muscle":                @(muscleKg),
                      @"musclePercent":         @(r1(data.musclePercent)),
                      @"water":                 @(r1(data.moisturePercent)),
                      @"bone":                  @(r1(data.boneMass)),
                      @"protein":               @(r1(data.proteinPercent)),
                      @"bmr":                   @(data.bmr),
                      @"visceral":              @(r1(data.visceralFat)),
                      @"skeletal_muscle":       @(skeletalMuscleKg),
                      @"skeletalMusclePercent": @(r1(data.smPercent)),
                      @"subcutaneous":          @(r1(data.subcutaneousFatPercent)),
                      @"body_age":              @(data.physicalAge),
                      @"ci":                    @(r1(data.smi)),
                      @"body_score":            @(r1(data.bodyScore)),
                      @"temperature":           @(data.temperature),
                      @"heartRate":             @(data.hr),
                      @"impedance":             @(data.imp)}];
}

#pragma mark - AirBP — CBPeripheralDelegate (Nordic UART)

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (self.activeMapping.protocolPath != VTMProtocolPathAirBP) return;
    if (error) {
        [self sendEvent:@{@"event": @"connectionState",
                          @"state": @"disconnected",
                          @"reason": error.localizedDescription ?: @"discover_services_failed"}];
        return;
    }
    for (CBService *svc in peripheral.services) {
        if ([svc.UUID.UUIDString caseInsensitiveCompare:kAirBPServiceUUID] == NSOrderedSame) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kAirBPTxCharUUID],
                                                  [CBUUID UUIDWithString:kAirBPRxCharUUID]]
                                     forService:svc];
            return;
        }
    }
    [self sendEvent:@{@"event": @"connectionState",
                      @"state": @"disconnected",
                      @"reason": @"airbp_service_not_found"}];
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    if (self.activeMapping.protocolPath != VTMProtocolPathAirBP) return;
    if (error) {
        [self sendEvent:@{@"event": @"connectionState",
                          @"state": @"disconnected",
                          @"reason": error.localizedDescription ?: @"discover_chars_failed"}];
        return;
    }
    for (CBCharacteristic *ch in service.characteristics) {
        if ([ch.UUID.UUIDString caseInsensitiveCompare:kAirBPTxCharUUID] == NSOrderedSame) {
            self.airBPTxChar = ch;
        } else if ([ch.UUID.UUIDString caseInsensitiveCompare:kAirBPRxCharUUID] == NSOrderedSame) {
            self.airBPRxChar = ch;
            [peripheral setNotifyValue:YES forCharacteristic:ch];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (self.activeMapping.protocolPath != VTMProtocolPathAirBP) return;
    if ([characteristic.UUID.UUIDString caseInsensitiveCompare:kAirBPRxCharUUID] != NSOrderedSame) return;
    if (error) {
        [self sendEvent:@{@"event": @"connectionState",
                          @"state": @"disconnected",
                          @"reason": error.localizedDescription ?: @"subscribe_failed"}];
        return;
    }
    if (!characteristic.isNotifying) return;
    self.serviceDeployed = YES;
    self.connectedModel  = self.activeMapping.lepuModel;
    [self sendEvent:@{@"event": @"connectionState",
                      @"state": @"connected",
                      @"model": @(self.connectedModel),
                      @"family": self.activeMapping.family ?: @"airbp",
                      @"deviceType": self.activeMapping.deviceType ?: @"bp",
                      @"sdk": @"airbp"}];
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (self.activeMapping.protocolPath != VTMProtocolPathAirBP) return;
    if (error || characteristic.value.length == 0) return;
    if ([characteristic.UUID.UUIDString caseInsensitiveCompare:kAirBPRxCharUUID] != NSOrderedSame) return;

    [self.airBPRxBuffer appendData:characteristic.value];
    [self drainAirBPBuffer];
}

#pragma mark - AirBP — helpers

- (void)writeAirBPCommand:(uint8_t)cmd payload:(nullable NSData *)payload {
    if (self.airBPTxChar == nil || self.activePeripheral == nil) return;
    NSData *frame = [VTAirBPPacket buildCommand:cmd payload:payload];
    CBCharacteristicWriteType type = (self.airBPTxChar.properties & CBCharacteristicPropertyWrite)
        ? CBCharacteristicWriteWithResponse
        : CBCharacteristicWriteWithoutResponse;
    [self.activePeripheral writeValue:frame forCharacteristic:self.airBPTxChar type:type];
}

/// Drain the rolling RX buffer, emitting one event per well-formed frame and
/// leaving any trailing partial bytes in the buffer for the next packet.
- (void)drainAirBPBuffer {
    while (self.airBPRxBuffer.length >= 9) {
        const uint8_t *p = self.airBPRxBuffer.bytes;
        if (p[0] != 0xA5) {
            // Re-sync: drop bytes until we find a header or run out.
            NSRange hdr = [self.airBPRxBuffer rangeOfData:[NSData dataWithBytes:"\xA5" length:1]
                                                 options:0
                                                   range:NSMakeRange(0, self.airBPRxBuffer.length)];
            if (hdr.location == NSNotFound) {
                [self.airBPRxBuffer setLength:0];
                return;
            }
            [self.airBPRxBuffer replaceBytesInRange:NSMakeRange(0, hdr.location)
                                           withBytes:NULL length:0];
            continue;
        }
        uint16_t payloadLen = (uint16_t)p[4] | ((uint16_t)p[5] << 8);
        NSUInteger frameLen = 8 + payloadLen + 1;
        if (self.airBPRxBuffer.length < frameLen) return; // wait for more bytes

        NSData *frame = [self.airBPRxBuffer subdataWithRange:NSMakeRange(0, frameLen)];
        uint8_t cmd = 0;
        NSData *info = [VTAirBPPacket parseFrame:frame cmd:&cmd];
        [self.airBPRxBuffer replaceBytesInRange:NSMakeRange(0, frameLen) withBytes:NULL length:0];
        if (info == nil) continue;              // CRC mismatch — drop this frame
        [self handleAirBPFrameCmd:cmd payload:info];
    }
}

- (void)handleAirBPFrameCmd:(uint8_t)cmd payload:(NSData *)payload {
    NSString *mac = self.activePeripheral.identifier.UUIDString ?: @"";
    NSString *fam = self.activeMapping.family ?: @"airbp";

    switch (cmd) {
        case VTAirBPCmdStartMeasure:
        case VTAirBPCmdEngineeringStart: {
            // Payload: int16 pressure_static, int16 pressure_pulse (both LE × 100).
            if (payload.length < 4) return;
            const int8_t *b = payload.bytes;
            int16_t pStatic = (int16_t)((uint8_t)b[0] | ((uint8_t)b[1] << 8));
            int16_t pPulse  = (int16_t)((uint8_t)b[2] | ((uint8_t)b[3] << 8));
            [self sendEvent:@{@"event": @"rtData",
                              @"deviceType":   @"bp",
                              @"deviceFamily": fam,
                              @"sdk":          @"airbp",
                              @"mac":          mac,
                              @"model":        @(self.connectedModel),
                              @"measureType":  @"bp_measuring",
                              @"pressure":     @(pStatic / 100.0),
                              @"pressureRaw":  @(pStatic),
                              @"pulseWave":    @(pPulse),
                              @"pulseWaveRaw": @(pPulse)}];
            break;
        }
        case VTAirBPCmdStopMeasure: {
            [self sendEvent:@{@"event": @"measurementStopped",
                              @"sdk":   @"airbp",
                              @"mac":   mac}];
            break;
        }
        case VTAirBPCmdRunningStatus: {
            if (payload.length < 1) return;
            uint8_t status = ((const uint8_t *)payload.bytes)[0];
            [self sendEvent:@{@"event":        @"rtData",
                              @"deviceType":   @"bp",
                              @"deviceFamily": fam,
                              @"sdk":          @"airbp",
                              @"mac":          mac,
                              @"model":        @(self.connectedModel),
                              @"measureType":  @"bp_status",
                              @"status":       @(status)}];
            break;
        }
        case VTAirBPCmdMeasureResult: {
            // 16-byte record: y(2) m(1) d(1) h(1) mi(1) s(1) state(1)
            //                 sys(2) dia(2) mean(2) pr(2)
            if (payload.length < 16) return;
            const uint8_t *b = payload.bytes;
            uint16_t year  = (uint16_t)b[0] | ((uint16_t)b[1] << 8);
            int16_t sys   = (int16_t)((uint16_t)b[8]  | ((uint16_t)b[9]  << 8));
            int16_t dia   = (int16_t)((uint16_t)b[10] | ((uint16_t)b[11] << 8));
            int16_t mean  = (int16_t)((uint16_t)b[12] | ((uint16_t)b[13] << 8));
            uint16_t pr   = (uint16_t)b[14] | ((uint16_t)b[15] << 8);
            NSString *ts = [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d",
                            year, b[2], b[3], b[4], b[5], b[6]];
            [self sendEvent:@{@"event":        @"rtData",
                              @"deviceType":   @"bp",
                              @"deviceFamily": fam,
                              @"sdk":          @"airbp",
                              @"mac":          mac,
                              @"model":        @(self.connectedModel),
                              @"measureType":  @"bp_result",
                              @"sys":          @(sys),
                              @"dia":          @(dia),
                              @"mean":         @(mean),
                              @"pr":           @(pr),
                              @"state":        @(b[7]),
                              @"timestamp":    ts}];
            break;
        }
        case VTAirBPCmdGetInfo: {
            [self sendEvent:@{@"event": @"deviceInfo",
                              @"sdk":   @"airbp",
                              @"model": @(self.connectedModel),
                              @"mac":   mac,
                              @"raw":   [payload base64EncodedStringWithOptions:0]}];
            break;
        }
        case VTAirBPCmdGetBattery: {
            if (payload.length < 1) return;
            uint8_t percent = ((const uint8_t *)payload.bytes)[0];
            [self sendEvent:@{@"event":   @"battery",
                              @"sdk":     @"airbp",
                              @"mac":     mac,
                              @"percent": @(percent)}];
            break;
        }
        default: {
            [self sendEvent:@{@"event":   @"raw",
                              @"sdk":     @"airbp",
                              @"mac":     mac,
                              @"cmdType": @(cmd),
                              @"data":    [payload base64EncodedStringWithOptions:0]}];
            break;
        }
    }
}

@end
