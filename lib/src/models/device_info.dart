import 'device_models.dart';

/// Represents a discovered BLE device.
class LepuDeviceInfo {
  final String name;
  final String mac;
  final int model;
  final int rssi;
  final String sdk; // "lepu", "icomon", "lescale", "airbp"

  const LepuDeviceInfo({
    required this.name,
    required this.mac,
    required this.model,
    required this.rssi,
    this.sdk = 'lepu',
  });

  factory LepuDeviceInfo.fromMap(Map<String, dynamic> map) {
    return LepuDeviceInfo(
      name: (map['name'] as String?) ?? '',
      mac: (map['mac'] as String?) ?? '',
      model: (map['model'] as int?) ?? -1,
      rssi: (map['rssi'] as int?) ?? 0,
      sdk: (map['sdk'] as String?) ?? 'lepu',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'mac': mac,
    'model': model,
    'rssi': rssi,
    'sdk': sdk,
  };

  /// Returns a human-readable device type based on the model number.
  String get deviceType {
    if (sdk == 'icomon' || sdk == 'lescale' || model == 9999) return 'scale';
    if (LepuDeviceModels.isEcg(model)) return 'ecg';
    if (LepuDeviceModels.isOximeter(model)) return 'oximeter';
    if (LepuDeviceModels.isBp(model)) return 'bp';
    return 'unknown';
  }

  @override
  String toString() =>
      'LepuDeviceInfo($name, $mac, model=$model, rssi=$rssi, sdk=$sdk)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LepuDeviceInfo && mac == other.mac;

  @override
  int get hashCode => mac.hashCode;
}

/// Helper class for device model classification.
///
/// All membership sets are derived from [DeviceModels] so there is a single
/// source of truth — editing `device_models.dart` automatically updates
/// classification here.
class LepuDeviceModels {
  LepuDeviceModels._();

  static final Set<int> ecgModels = {...DeviceModels.allEcg};
  static final Set<int> oximeterModels = {...DeviceModels.allOximeter};
  static final Set<int> bpModels = {...DeviceModels.allBp};

  static bool isEcg(int model) => ecgModels.contains(model);
  static bool isOximeter(int model) => oximeterModels.contains(model);
  static bool isBp(int model) => bpModels.contains(model);
}
