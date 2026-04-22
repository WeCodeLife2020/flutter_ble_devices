# flutter_ble_devices

Flutter plugin for Viatom / Lepu BLE medical devices (ECG, Oximeter, Blood
Pressure, body scale). It wraps the official vendor SDKs so that one Dart
API works on both platforms:

| Platform | Native SDK used |
| --- | --- |
| Android | `lepu-blepro` (Lepu/Viatom AAR) + `ICDeviceManager` (iComon scales) |
| iOS     | [`VTMProductLib`](https://github.com/viatom-dev/VTProductLib) (CocoaPods) + `ICDeviceManager.xcframework` (iComon scales, vendored under `ios/Frameworks/`) |

The Dart API is exposed from `lib/flutter_ble_devices.dart` — the same
`BluetodevController.scan()`, `.connect()`, `.startMeasurement()`, and event
streams work on both platforms.

---

## Supported devices

### ECG
- ER1 / ER1-N / ER1-S / ER1-H / ER1-W / ER1-L / ER1-LW / VBeat (`family = "er1"`)
  - ER1-LW (ER1-L with WiFi) advertises as `ER1-LW` / `ER1LW` and shares
    `MODEL_ER1_L = 148` with ER1-L.
- ER2 / ER2-S / DuoEK / DuoEK-S (`family = "er2"`)
- Lepod / Lepod Pro (`family = "er3"`)
- M12 / M5 (`family = "mseries"`)

### Oximeter
- O2Ring / O2M / BabyO2 / CheckO2 / SleepO2 / SnoreO2 / SleepU / OxyLink /
  KidsO2 / Oxyfit / OxyRing / BBSM-S1/S2 (`family = "oxy"` — legacy AA
  header, uses `VTO2Communicate` on iOS)
- O2Ring S (`family = "woxi"`)
- PF-10AW / PF-10AW1 / PF-10AW_1 / PF-10BW / PF-10BW1 / PF-10BWS
  (`family = "foxi"`) — each advertised name maps to the exact Lepu
  `MODEL_PF_10*` id listed in [`ios/Classes/VTMDeviceTypeMapper.m`](ios/Classes/VTMDeviceTypeMapper.m).

### Blood pressure
- BP2 / BP2A / BP2T / BP2W / BP2 Pro (`family = "bp2"`)
- BP3 family (`family = "bp3"`)
- **AirBP / SmartBP** (`family = "airbp"`, `sdk = "airbp"`) — structured `sys`/`dia`/`mean`/`pr` on both platforms via the [viatom-dev/iOSAirBP](https://github.com/viatom-dev/iOSAirBP) protocol (no external SDK needed; parsers live in `ios/Classes/VTAirBPPacket.*`)

### Scale
- Viatom S1 body-composition scale (iOS only — `family = "scale"`, VTProductLib)
- iComon / Welland body-composition scales (**both platforms** — Android AAR / iOS `ICDeviceManager.xcframework`)
- **LESCALE F4** and other Fitdays-protocol scales — handled by the
  cross-platform [`LescaleController`](lib/src/lescale_controller.dart)
  which drives the peripheral with `flutter_blue_plus` directly and does
  not rely on the Lepu or iComon native bridges. Advertises model id
  `DeviceModels.lescaleF4` (`9999`).

---

## Install

```yaml
dependencies:
  flutter_ble_devices:
    path: ../flutter_ble_devices   # or the published version
```

### Android

The AARs are already vendored in `android/libs/`. Nothing else is required.

#### Updating the Lepu AAR

The vendored `lepu-blepro-1.2.0.aar` has been post-processed so that every
`Log.d` / `toString()` / error-message string embedded in the compiled
classes reads in English rather than Chinese. Our plugin's own logs, and
the iOS `VTMProductLib`, are already English-only; the Android patcher
closes the last gap.

When Lepu ships a new AAR, re-run the patcher:

```sh
# 1. Drop the new vendor AAR into android/libs/, overwriting the old one.
cp <new>/lepu-blepro-X.Y.Z.aar android/libs/lepu-blepro-1.2.0.aar

# 2. Run the patcher (idempotent; creates a .orig backup on first run).
python3 tools/translate_lepu_aar.py
```

The script walks every `CONSTANT_Utf8` entry in every `.class` file inside
the AAR's `classes.jar`, replaces each Chinese literal with its English
translation, and re-packs the AAR in place. It fails loudly if a new
Chinese literal shows up with no mapping, so you'll get a list of strings
to translate before the AAR is considered clean.

### iOS

The iOS plugin ships as two CocoaPods subspecs:

| Subspec | What it pulls in | Devices it enables |
| --- | --- | --- |
| **`Core`** *(default)* | `VTMProductLib` (Obj-C xcframework from CocoaPods) + the AirBP Nordic-UART parser baked into this repo | ECG (ER1/ER2/ER3/M-series), BP2/BP3, Viatom oximeters (legacy `0xAA` **and** URAT/FOxi/WOxi), Viatom S1 scale, AirBP / SmartBP |
| **`IComon`** *(opt-in)* | Everything in `Core` plus the four vendored iComon xcframeworks (`ICDeviceManager`, `ICBleProtocol`, `ICBodyFatAlgorithms`, `ICLogger`) | iComon / Welland body-composition scales |

The **IComon subspec is opt-in on purpose**. Those xcframeworks register
Obj-C classes named `ICDevice`, `ICDeviceManager`, and `ICDeviceInfo`,
which **collide with Apple's own `ImageCaptureCore.framework`** and the
private `iTunesCloud.framework`. Apps that don't need scale support
should stay on `Core` to avoid the runtime warning:

```
objc[…]: Class ICDeviceManager is implemented in both
  /System/Library/Frameworks/ImageCaptureCore.framework/ImageCaptureCore
  AND /path/to/Runner.app/Runner.debug.dylib
  This may cause spurious casting failures and mysterious crashes.
```

#### Default install (ECG/BP/Oximeter/AirBP only)

```sh
cd ios && pod install
```

That's it — the default `Core` subspec is selected automatically.

#### Opting into iComon scale support

Edit your app's `ios/Podfile` and declare the subspecs explicitly:

```ruby
target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Pull both subspecs so body-composition scales work.
  pod 'flutter_ble_devices',
      :path     => '.symlinks/plugins/flutter_ble_devices/ios',
      :subspecs => ['Core', 'IComon']
end
```

Then `pod install --repo-update`. The iComon SDK is linked, and
`FlutterBleDevicesPlugin.m` automatically picks up the iComon code paths
via `__has_include(<ICDeviceManager/ICDeviceManager.h>)` — no manual
flags needed.

If a call to `connect(sdk: 'icomon', …)` reaches an app built without the
`IComon` subspec, the plugin returns a clean `UNSUPPORTED` method-channel
error instead of crashing.

#### `Info.plist` keys

Required on **both** subspec configurations:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>We use Bluetooth to communicate with your medical device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>We use Bluetooth to communicate with your medical device.</string>
```

Minimum iOS deployment target: **iOS 11**. All vendored xcframeworks are
device-only arm64 (no `ios-arm64-simulator` slice), so the podspec excludes
`arm64` from the simulator build — run on a **physical device**.

#### Updating the iComon SDK

The iComon SDK currently vendored is `iOS_1.3.0_b1312`. When the vendor
ships a new version, drop it somewhere outside the repo and copy the four
xcframeworks over the old ones, then re-run pod install:

```sh
cp -R <new-sdk-drop>/SDK/ICDeviceManager.xcframework     ios/Frameworks/
cp -R <new-sdk-drop>/SDK/ICBleProtocol.xcframework       ios/Frameworks/
cp -R <new-sdk-drop>/SDK/ICBodyFatAlgorithms.xcframework ios/Frameworks/
cp -R <new-sdk-drop>/SDK/ICLogger.xcframework            ios/Frameworks/
cd ios && pod install
```

---

## Quick start

```dart
import 'package:flutter_ble_devices/flutter_ble_devices.dart';

// 1. Permissions + service init
await BluetodevController.requestPermissions();
await BluetodevController.initService();

// 2. Listen
BluetodevController.scanStream.listen((dev) {
  print('found ${dev.name} (${dev.mac}) model=${dev.model}');
});
BluetodevController.measurementStream.listen((m) {
  print('hr=${m.hr} spo2=${m.spo2} sys=${m.sys}/${m.dia}');
});

// 3. Scan → connect → measure
await BluetodevController.scan();
// ... user picks a device ...
await BluetodevController.connect(model: device.model, mac: device.mac);
await BluetodevController.startMeasurement();               // default mode
// BP2/BP2A/BP2T/BP2W → `mode` selects the device state first
await BluetodevController.startMeasurement(mode: 'bp');     // or 'ecg' / 'history' / 'ready' / 'off'
```

---

## iOS ↔ Android compatibility notes

| Concept | Android | iOS |
| --- | --- | --- |
| `mac` string | Real BT MAC (`AA:BB:CC:...`) | VT path: CBPeripheral `UUID` string. iComon path: MAC-style string synthesised by `ICDeviceManager` from the peripheral UUID. Both are opaque identifiers you can pass straight back to `connect(mac:...)`. |
| `model` integer | `Bluetooth.MODEL_*` from Lepu SDK | Same ids — mapped from the advertised name by `VTMDeviceTypeMapper` |
| Scanning filter | Lepu native filter by model | Client-side filter by model after name classification |
| iComon scales | Supported (`sdk: 'icomon'`) | Supported (`sdk: 'icomon'`) via `ICDeviceManager.xcframework` |
| Real-time ECG (ER1/ER2) | Structured `ecgFloats`/`ecgShorts` | Structured `ecgFloats`/`ecgShorts` via `VTMBLEParser` |
| Real-time O2 (AA path) | Structured | Structured, via `VTO2Parser` |
| Real-time BP2 / BP2A / BP2T / BP2W | Structured (`measureType`, `sys`, `dia`, `mean`, `pr`, `pressure`, `ecgFloats`, …) | **Structured** via `VTMBLEParser (BP)` — same field names as Android. `startMeasurement(mode: 'bp'/'ecg')` drives the device-side state switch that Android's `BleServiceHelper.startRtTask` does internally. |
| Real-time WOxi (O2Ring S) | Structured (`spo2`, `pr`, `pi`, `waveData`, …) | **Structured** via `VTMBLEParser.woxi_parseRealData:` |
| Real-time FOxi (PF-10BWS family) | Structured | **Structured** via `VTMBLEParser.foxi_parseMeasureInfo:` / `foxi_parseMeasureWave:` |
| Real-time Scale (S1 / F4) | Structured | **Structured** via `VTMBLEParser (Scale)` |
| Real-time ER3 / M-series | Structured | **Structured** via `VTMBLEParser.parseER3RealTimeData:` / `parseMSeriesRunParams:` (compressed waveform surfaced as base64) |
| Real-time AirBP | Scan-only — no AirBP-specific handler wired in the Android plugin yet. | Fully wired: structured `sys`/`dia`/`mean`/`pr` + live `pressure` via `VTAirBPPacket` (plain Nordic UART, no external SDK). |

### Polling vs push

The Android Lepu SDK's `BleServiceHelper.startRtTask(model)` drives the
real-time command pipe internally, so Dart just sees events flow. On iOS
most URAT commands (`requestECGRealData`, `requestBPRealData`,
`requestScaleRealData`, `requestER3ECGRealData`, `baby_requestRunParams`)
are one-shot GETs, so the plugin runs a light `NSTimer`-based poll at
300–500 ms cadence for those families. `WOxi` and `FOxi` use push
subscriptions (`observeParameters:` / `foxi_makeInfoSend:`), so those are
**not** polled. `stopMeasurement` and `disconnect` tear the timer down.

### Model-id mapping (summary)

The iOS side deliberately re-uses the same integer ids as the Lepu Android
SDK so the Dart layer doesn't need to branch per platform. Mapping lives in
`ios/Classes/VTMDeviceTypeMapper.m`.

---

## Event schema (both platforms)

Emitted on `BluetodevController.eventStream`:

```
{ 'event': 'serviceReady' }
{ 'event': 'deviceFound', 'name', 'mac', 'model', 'rssi', 'sdk', 'deviceType', 'family' }
{ 'event': 'connectionState', 'state': 'connected'|'disconnected', 'model', ... }
{ 'event': 'rtData', 'deviceType', 'deviceFamily', 'model', <fields> }
{ 'event': 'rtWaveform', 'deviceType', 'deviceFamily', 'model', <fields> }
{ 'event': 'deviceInfo', 'model', ... }
{ 'event': 'fileList',  'model', 'files': [...] }
{ 'event': 'battery',   'state', 'percent', 'voltage' }
```

### `rtData` fields per family

| `deviceFamily` | Fields |
| --- | --- |
| `er1`, `er2` | `hr`, `battery`, `batteryState`, `recordTime`, `curStatus`, `ecgFloats` (mV), `ecgShorts`, `samplingRate`, `mvConversion` |
| `bp2`, `bp3` | `deviceStatus`, `batteryState`, `batteryPercent`, `paramDataType`, `measureType` ∈ {`bp_measuring`, `bp_result`, `ecg_measuring`, `ecg_result`, `idle`, `bp_status`, `bp_pressure`}, plus per-measureType fields: **bp_measuring** `pressure`, `pr`, `isDeflate`, `isPulse`; **bp_result** `sys`, `dia`, `mean`, `pr`, `result`, `stateCode`; **ecg_measuring** `hr`, `curDuration`, `isLeadOff`, `isPoolSignal`, `ecgFloats`, `ecgShorts`, `samplingRate`, `mvConversion`; **ecg_result** `hr`, `qrs`, `pvcs`, `qtc`, `result` |
| `airbp` | `measureType` ∈ {`bp_measuring`, `bp_result`, `bp_status`}, `pressure`, `pulseWave`, `sys`, `dia`, `mean`, `pr`, `state`, `timestamp` |
| `oxy` (legacy) | `spo2`, `pr`, `pi`, `battery`, `batteryState`, `state`, `vector` |
| `woxi` | `spo2`, `pr`, `pi`, `battery`, `batteryState`, `state`, `sensorState`, `motion`, `recordTime`, `waveData` |
| `foxi` | `spo2`, `pr`, `pi`, `status`, `batLevel`, `probeOff` |
| `scale` (S1) | `weightKg`, `impedance`, `heartRate`, `runStatus`, `leadStatus` |
| `icomon` | `weightKg`, `bmi`, `fat`, `fat_mass`, `muscle`, `musclePercent`, `water`, `bone`, `protein`, `bmr`, `visceral`, `skeletal_muscle`, `subcutaneous`, `body_age`, `body_score`, `heartRate`, `impedance` |
| `er3`, `mseries` | `hr`, `spo2`, `pr`, `pi`, `temperature`, `respRate`, `battery`, `batteryState`, `runStatus`, `leadMode`, `leadState`, `samplingNum`, `waveInfo` |
| `baby` | `runStatus`, `attitude`, `wearStatus`, `rr`, `alarmTypeRR`, `temperature`, `alarmTypeTemp`, `battery`, `batteryState`, `startupTime`, `gestureAlarm` |

On iOS, unstructured device responses (unmapped cmdTypes) are emitted as:

```
{ 'event': 'raw', 'cmdType', 'deviceType', 'data': '<base64>' }
```

---

## License

MIT — see [`LICENSE`](./LICENSE). `VTMProductLib` and `lepu-blepro` are
licensed separately by their respective vendors.
