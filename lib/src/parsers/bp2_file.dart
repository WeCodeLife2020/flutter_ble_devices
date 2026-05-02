// BP2 recorded-file decoders. BP2 / BP2A / BP2T blood-pressure monitors
// store each measurement as a short binary blob. Two format variants
// exist, distinguished by byte[1] ("fileType"):
//
//   fileType == 1 → blood-pressure result (19 bytes, no waveform)
//   fileType == 2 → ECG recording        (header + 16-bit LE wave data)
//
// The byte layouts below are reverse-engineered from the Lepu AAR
// bundled with this plugin (`lepu-blepro-1.2.0.aar`, classes
// `com.lepu.blepro.ext.bp2.BpFile` and `EcgFile`). The parsers are
// byte-for-byte compatible with those SDK classes, so code that
// previously used reflection to pull fields off the Java objects can
// switch to this pure-Dart path without behavioural change.
//
// NOTE on timestamps: the raw little-endian u32 in the file stores the
// measurement as *local-time-as-if-UTC* (i.e. the u32 encodes the wall
// clock of the device's timezone as Unix seconds).  To recover a real
// UTC Unix timestamp, the Android SDK subtracts the current phone's
// timezone offset.  This Dart port does the same — but the raw value
// is also exposed as [measureTimeRaw] so the caller can apply a
// different timezone if needed (e.g. when replaying files captured
// in a different region).

import 'dart:typed_data';

import 'ecg_diagnosis.dart';

/// BP2 ECG's per-sample conversion constant, matching the Lepu RT path
/// (`mV = short * 0.003098`).  The same constant is applied to file-
/// stored samples.
const double kBp2EcgMvConversion = 0.003098;

/// BP2 ECG sampling rate (Hz).
const int kBp2EcgSamplingRate = 250;

/// Common superclass for the two BP2 file variants. Use
/// [Bp2File.parse] which auto-discriminates on `fileType`.
abstract class Bp2File {
  /// File-format version (byte[0]).
  final int fileVersion;

  /// `1` = BP measurement, `2` = ECG recording.
  final int fileType;

  /// UTC unix timestamp (seconds), adjusted for the phone's current
  /// timezone offset just as the Android SDK does.
  final int measureTime;

  /// The raw u32 as stored on the device, before tz-adjustment.  Same
  /// value the Lepu SDK reads from bytes[2..6] little-endian.
  final int measureTimeRaw;

  /// Original payload, in case the caller wants to re-parse.
  final Uint8List bytes;

  Bp2File({
    required this.fileVersion,
    required this.fileType,
    required this.measureTime,
    required this.measureTimeRaw,
    required this.bytes,
  });

  /// Decode any BP2 file.  Returns [Bp2BpFile] when `fileType == 1`,
  /// [Bp2EcgFile] when `fileType == 2`, or [Bp2UnknownFile] otherwise.
  static Bp2File parse(List<int> raw, {Duration? timezoneOffset}) {
    if (raw.length < 2) {
      throw ArgumentError('BP2 file too short: ${raw.length} bytes');
    }
    final type = raw[1] & 0xFF;
    switch (type) {
      case 1:
        return Bp2BpFile._parse(raw, timezoneOffset: timezoneOffset);
      case 2:
        return Bp2EcgFile._parse(raw, timezoneOffset: timezoneOffset);
      default:
        return Bp2UnknownFile._(
          fileVersion: raw[0] & 0xFF,
          fileType: type,
          measureTime: 0,
          measureTimeRaw: 0,
          bytes: Uint8List.fromList(raw),
        );
    }
  }
}

/// BP2 blood-pressure measurement (fileType == 1).
///
/// Byte layout (offsets in bytes, all multi-byte integers are
/// little-endian):
///
/// | Offset | Size | Field         |
/// | ---    | ---  | ---           |
/// | `0`    | `1`  | fileVersion   |
/// | `1`    | `1`  | fileType (=1) |
/// | `2..6` | `4`  | measureTime (u32, minus tz offset) |
/// | `11..13` | `2` | sys (mmHg)   |
/// | `13..15` | `2` | dia (mmHg)   |
/// | `15..17` | `2` | mean (mmHg)  |
/// | `17`   | `1`  | pulse rate (bpm) |
/// | `18`   | `1`  | result; `arrhythmia == (result == 1)` |
class Bp2BpFile extends Bp2File {
  /// Systolic pressure in mmHg.
  final int sys;

  /// Diastolic pressure in mmHg.
  final int dia;

  /// Mean arterial pressure in mmHg.
  final int mean;

  /// Pulse rate in bpm.
  final int pr;

  /// Raw result byte (0 = normal, 1 = arrhythmia detected, rest
  /// reserved for future use).
  final int result;

  /// True iff the device flagged an arrhythmia (`result == 1`).
  final bool arrhythmia;

  Bp2BpFile._({
    required super.fileVersion,
    required super.fileType,
    required super.measureTime,
    required super.measureTimeRaw,
    required super.bytes,
    required this.sys,
    required this.dia,
    required this.mean,
    required this.pr,
    required this.result,
    required this.arrhythmia,
  });

  factory Bp2BpFile._parse(List<int> raw, {Duration? timezoneOffset}) {
    if (raw.length < 19) {
      throw ArgumentError('BP2 BP file too short: ${raw.length} bytes');
    }
    final tzSec = (timezoneOffset ?? DateTime.now().timeZoneOffset).inSeconds;
    final measureTimeRaw = _u32Le(raw, 2);
    final result = raw[18] & 0xFF;
    return Bp2BpFile._(
      fileVersion: raw[0] & 0xFF,
      fileType: raw[1] & 0xFF,
      measureTimeRaw: measureTimeRaw,
      measureTime: measureTimeRaw - tzSec,
      bytes: Uint8List.fromList(raw),
      sys: _u16Le(raw, 11),
      dia: _u16Le(raw, 13),
      mean: _u16Le(raw, 15),
      pr: raw[17] & 0xFF,
      result: result,
      arrhythmia: result == 1,
    );
  }

  /// Measurement time as a local `DateTime` (uses `measureTime`).
  DateTime get measuredAt => DateTime.fromMillisecondsSinceEpoch(
    measureTime * 1000,
    isUtc: true,
  ).toLocal();

  @override
  String toString() =>
      'Bp2BpFile(sys=$sys dia=$dia mean=$mean pr=$pr'
      '${arrhythmia ? " arrhythmia" : ""} @ $measuredAt)';
}

/// BP2 ECG recording (fileType == 2).
///
/// The recording is a fixed 48-byte header followed by raw 16-bit LE
/// samples at 250 Hz. Byte layout:
///
/// | Offset | Size | Field |
/// | ---    | ---  | --- |
/// | `0`    | `1`  | fileVersion |
/// | `1`    | `1`  | fileType (=2) |
/// | `2..6` | `4`  | measureTime (u32, minus tz offset) |
/// | `10..14` | `4` | recordingTime (seconds) |
/// | `16..20` | `4` | result — doubles as the diagnosis bit-mask |
/// | `20..22` | `2` | hr (bpm) |
/// | `22..24` | `2` | qrs (ms) |
/// | `24..26` | `2` | pvcs |
/// | `26..28` | `2` | qtc (ms) |
/// | `28`   | `1`  | connectCable (1 = cable attached) |
/// | `48..end` | `*` | signed 16-bit LE samples |
class Bp2EcgFile extends Bp2File {
  /// Duration of the recording in seconds (typically 30 for BP2).
  final int recordingTime;

  /// Raw 32-bit diagnosis value; same bytes also feed [diagnosis].
  final int result;

  /// Typed diagnosis flags extracted from [result].
  final EcgDiagnosis diagnosis;

  /// Heart rate (bpm).
  final int hr;

  /// QRS duration (ms).
  final int qrs;

  /// PVC count.
  final int pvcs;

  /// QTc interval (ms).
  final int qtc;

  /// True iff the ECG cable was plugged into the cuff during capture
  /// (byte[28] == 1).  Some BP2 models allow external-cable ECG in
  /// addition to the built-in finger electrodes.
  final bool connectCable;

  /// Raw ECG samples as signed 16-bit integers, at
  /// [kBp2EcgSamplingRate] Hz.  Length == `recordingTime * 250`.
  final Int16List waveShortData;

  /// Convenience view: samples converted to millivolts (by
  /// multiplying each short by [kBp2EcgMvConversion]).
  final Float32List waveFloatData;

  /// Raw bytes of the waveform section (bytes[48..end]).  Kept for
  /// consumers who want to hand the payload to native code or re-parse.
  final Uint8List waveData;

  Bp2EcgFile._({
    required super.fileVersion,
    required super.fileType,
    required super.measureTime,
    required super.measureTimeRaw,
    required super.bytes,
    required this.recordingTime,
    required this.result,
    required this.diagnosis,
    required this.hr,
    required this.qrs,
    required this.pvcs,
    required this.qtc,
    required this.connectCable,
    required this.waveShortData,
    required this.waveFloatData,
    required this.waveData,
  });

  factory Bp2EcgFile._parse(List<int> raw, {Duration? timezoneOffset}) {
    if (raw.length < 48) {
      throw ArgumentError(
        'BP2 ECG file too short: ${raw.length} bytes '
        '(need ≥48 for the header)',
      );
    }
    final tzSec = (timezoneOffset ?? DateTime.now().timeZoneOffset).inSeconds;
    final measureTimeRaw = _u32Le(raw, 2);
    final result = _u32Le(raw, 16).toSigned(32);

    // Waveform occupies the remainder of the file, two bytes per sample.
    final waveBytes = Uint8List.fromList(raw.sublist(48));
    final sampleCount = waveBytes.length ~/ 2;
    final shorts = Int16List(sampleCount);
    final floats = Float32List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final lo = waveBytes[i * 2] & 0xFF;
      final hi = waveBytes[i * 2 + 1] & 0xFF;
      // The Android SDK uses `doab.doab(lo, hi)` which builds a signed
      // short from `(lo) + (hi << 8)`.  Cast to signed via toSigned(16).
      final s = (lo | (hi << 8)).toSigned(16);
      shorts[i] = s;
      floats[i] = s * kBp2EcgMvConversion;
    }

    return Bp2EcgFile._(
      fileVersion: raw[0] & 0xFF,
      fileType: raw[1] & 0xFF,
      measureTimeRaw: measureTimeRaw,
      measureTime: measureTimeRaw - tzSec,
      bytes: Uint8List.fromList(raw),
      recordingTime: _u32Le(raw, 10),
      result: result,
      diagnosis: EcgDiagnosis.fromInt(result),
      hr: _u16Le(raw, 20),
      qrs: _u16Le(raw, 22),
      pvcs: _u16Le(raw, 24),
      qtc: _u16Le(raw, 26),
      connectCable: (raw[28] & 0xFF) == 1,
      waveShortData: shorts,
      waveFloatData: floats,
      waveData: waveBytes,
    );
  }

  /// Measurement time as a local `DateTime`.
  DateTime get measuredAt => DateTime.fromMillisecondsSinceEpoch(
    measureTime * 1000,
    isUtc: true,
  ).toLocal();

  /// Recording duration as a [Duration].
  Duration get duration => Duration(seconds: recordingTime);

  @override
  String toString() =>
      'Bp2EcgFile(hr=$hr qrs=$qrs pvcs=$pvcs qtc=$qtc'
      ' duration=${recordingTime}s samples=${waveShortData.length}'
      ' ${diagnosis.findings.join(", ")} @ $measuredAt)';
}

/// Fallback wrapper for a BP2 file whose `fileType` byte didn't match
/// any documented variant — exposes the raw bytes so the caller can
/// either handle the new format themselves or forward an `err` to the
/// user.  We return this rather than throwing so a firmware bump
/// doesn't break the download pipeline.
class Bp2UnknownFile extends Bp2File {
  Bp2UnknownFile._({
    required super.fileVersion,
    required super.fileType,
    required super.measureTime,
    required super.measureTimeRaw,
    required super.bytes,
  });

  @override
  String toString() =>
      'Bp2UnknownFile(fileType=$fileType size=${bytes.length})';
}

int _u16Le(List<int> b, int o) => (b[o] & 0xFF) | ((b[o + 1] & 0xFF) << 8);

int _u32Le(List<int> b, int o) =>
    (b[o] & 0xFF) |
    ((b[o + 1] & 0xFF) << 8) |
    ((b[o + 2] & 0xFF) << 16) |
    ((b[o + 3] & 0xFF) << 24);
