// Typed event models for the on-device file-transfer pipeline.
//
// Wire format (emitted by both the Android Kotlin plugin and the iOS
// Obj-C plugin — `FlutterBleDevicesPlugin.kt`/`.m`):
//
//   { event: 'fileList',         model, deviceFamily?, files: [String] }
//   { event: 'fileReadProgress', model, deviceFamily,  fileName?, progress: 0..1 }
//   { event: 'fileReadComplete', model, deviceFamily,  fileName,
//                                size,  content: <base64>?, parsed?: { ... } }
//   { event: 'fileReadError',    model, deviceFamily,  fileName?, error }
//
// `content` is base64-encoded raw file bytes when the SDK exposes them;
// `parsed` is a best-effort family-specific map of typed fields the SDK
// has already parsed for us (e.g. SpO2 lists for oximeters).

import 'dart:convert';
import 'dart:typed_data';

/// Response to [BluetodevController.getFileList].
class FileListEvent {
  /// Lepu/iComon model id for which this list applies.
  final int model;

  /// Family token: `"er1"`, `"er2"`, `"bp2"`, `"oxy"`, `"oxyII"`,
  /// `"pf10aw1"`, etc.  Always present on Android, present on iOS for
  /// every family that supports listing.
  final String? deviceFamily;

  /// Filenames stored on the device's flash, oldest-first.  Pass each
  /// entry to [BluetodevController.readFile] to download the file.
  final List<String> files;

  const FileListEvent({
    required this.model,
    required this.files,
    this.deviceFamily,
  });

  factory FileListEvent.fromMap(Map<String, dynamic> m) => FileListEvent(
        model: (m['model'] as num?)?.toInt() ?? -1,
        deviceFamily: m['deviceFamily'] as String?,
        files: ((m['files'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );

  @override
  String toString() =>
      'FileListEvent(model=$model, family=$deviceFamily, files=${files.length})';
}

/// Per-chunk progress update during a file download.
class FileReadProgressEvent {
  final int model;
  final String deviceFamily;
  final String? fileName;

  /// Fraction in `0.0 ... 1.0`.  Plugins normalise the SDK's native
  /// progress (which may arrive as `0..100` integers) to this range.
  final double progress;

  const FileReadProgressEvent({
    required this.model,
    required this.deviceFamily,
    required this.progress,
    this.fileName,
  });

  factory FileReadProgressEvent.fromMap(Map<String, dynamic> m) =>
      FileReadProgressEvent(
        model: (m['model'] as num?)?.toInt() ?? -1,
        deviceFamily: (m['deviceFamily'] as String?) ?? 'unknown',
        fileName: m['fileName'] as String?,
        progress: (m['progress'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  String toString() => 'FileReadProgress($deviceFamily $fileName '
      '${(progress * 100).toStringAsFixed(1)}%)';
}

/// Final event of a successful file download.
class FileReadCompleteEvent {
  final int model;
  final String deviceFamily;
  final String fileName;

  /// Decoded file bytes (may be empty if the SDK only exposes parsed
  /// fields and not the raw payload).
  final Uint8List content;

  /// Family-specific best-effort parsed fields, exactly as the vendor
  /// SDK already decoded them.  Keys depend on `deviceFamily`:
  ///
  ///  * `bp2`        — `fileName`, `type`, `content`
  ///  * `er1` / `er2` — `fileName`, `content`
  ///  * `oxy`        — `fileType`, `fileVersion`, `recordingTime`,
  ///                  `spo2List`, `prList`, `motionList`, `avgSpo2`,
  ///                  `asleepTime`, `asleepTimePercent`
  ///  * `oxyII`      — `fileType`, `startTime`, `interval`,
  ///                  `spo2List`, `prList`, `motionList`, `avgSpo2`,
  ///                  `minSpo2`, `avgHr`, `stepCounter`, `o2Score`, ...
  ///  * `pf10aw1`    — `fileType`, `startTime`, `endTime`, `interval`,
  ///                  `spo2List`, `prList`, ...
  ///
  /// On iOS the plugin only fills `parsed` for the legacy O2 path; for
  /// URAT-protocol families the raw [content] is delivered and Dart-side
  /// parsing is the consumer's responsibility.
  final Map<String, dynamic>? parsed;

  const FileReadCompleteEvent({
    required this.model,
    required this.deviceFamily,
    required this.fileName,
    required this.content,
    this.parsed,
  });

  factory FileReadCompleteEvent.fromMap(Map<String, dynamic> m) {
    final raw = m['content'];
    Uint8List bytes;
    if (raw is String) {
      try {
        bytes = base64Decode(raw);
      } catch (_) {
        bytes = Uint8List(0);
      }
    } else if (raw is List) {
      bytes = Uint8List.fromList(raw.cast<int>());
    } else {
      bytes = Uint8List(0);
    }
    final parsed = m['parsed'];
    return FileReadCompleteEvent(
      model: (m['model'] as num?)?.toInt() ?? -1,
      deviceFamily: (m['deviceFamily'] as String?) ?? 'unknown',
      fileName: (m['fileName'] as String?) ?? '',
      content: bytes,
      parsed: parsed is Map ? Map<String, dynamic>.from(parsed) : null,
    );
  }

  /// File size in bytes (equivalent to `content.length`).
  int get size => content.length;

  @override
  String toString() =>
      'FileReadComplete($deviceFamily $fileName $size bytes)';
}

/// Emitted on a download failure or cancellation.
class FileReadErrorEvent {
  final int model;
  final String deviceFamily;
  final String? fileName;
  final String error;

  const FileReadErrorEvent({
    required this.model,
    required this.deviceFamily,
    required this.error,
    this.fileName,
  });

  factory FileReadErrorEvent.fromMap(Map<String, dynamic> m) =>
      FileReadErrorEvent(
        model: (m['model'] as num?)?.toInt() ?? -1,
        deviceFamily: (m['deviceFamily'] as String?) ?? 'unknown',
        fileName: m['fileName'] as String?,
        error: (m['error'] as String?) ?? 'unknown',
      );

  @override
  String toString() => 'FileReadError($deviceFamily $fileName: $error)';
}
