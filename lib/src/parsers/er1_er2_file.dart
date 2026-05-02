// ER1 / ER2 recorded-file decoder. Both families share the same on-
// flash format — the Lepu AAR exposes them as
// `com.lepu.blepro.ext.er1.Er1EcgFile` and
// `com.lepu.blepro.ext.er2.Er2EcgFile`, but they're literally
// identical wrappers around the same `doad.docj` Kotlin parser.
//
// Layout (offsets in bytes, multi-byte ints are little-endian):
//
// | Offset    | Size  | Field         |
// | ---       | ---   | ---           |
// | `0`       | `1`   | fileVersion   |
// | `1..10`   | `9`   | reserved (device-specific header — sn / model / start time on some firmwares; the SDK ignores it) |
// | `10..n-20`| `*`   | waveData (signed 16-bit LE samples) |
// | `n-20..n-16` | `4`| recordingTime (u32, seconds)  |
// | `n-16..n-14` | `2`| dataCrc (u16, vendor checksum) |
// | `n-14..n-4`  | `10`| reserved                      |
// | `n-4..n`     | `4`| magic (u32 sentinel)         |
//
// Per-sample mV conversion mirrors the real-time path
// (`mV = short * 0.002467`, derived from the SDK's
// `1806.3 / 732119.04`).

import 'dart:typed_data';

/// ER1 / ER2 ECG sampling rate (Hz). Matches the RT-stream rate.
const int kEr1EcgSamplingRate = 125;

/// Per-sample millivolt conversion. Matches the Lepu RT path
/// (`mV = short * 1806.3 / 732119.04 ≈ 0.002467`).
const double kEr1EcgMvConversion = 1806.3 / 732119.04;

/// Decoded ER1 / ER2 ECG recording.
class Er1EcgFile {
  /// File-format version (byte[0]).
  final int fileVersion;

  /// Recording duration in seconds (decoded from the trailer).
  final int recordingTime;

  /// Vendor checksum recorded by the firmware.  Plugin does not verify
  /// this — it's exposed so the caller can audit if desired.
  final int dataCrc;

  /// Magic sentinel from the trailing 4 bytes (typical value
  /// `0x564f5331` = "VOS1" or similar; differs per firmware).
  final int magic;

  /// Raw waveform bytes (signed 16-bit LE pairs).
  final Uint8List waveData;

  /// Waveform as signed shorts.
  final Int16List waveShortData;

  /// Waveform converted to mV via [kEr1EcgMvConversion].
  final Float32List waveFloatData;

  /// Original file payload, in case the caller wants to re-parse.
  final Uint8List bytes;

  /// Family token: `er1` or `er2`. Always lowercase.
  final String family;

  Er1EcgFile._({
    required this.family,
    required this.fileVersion,
    required this.recordingTime,
    required this.dataCrc,
    required this.magic,
    required this.waveData,
    required this.waveShortData,
    required this.waveFloatData,
    required this.bytes,
  });

  /// Decode an ER1 file. The byte layout is identical to ER2 — the
  /// only difference is the family tag stored on the result.
  static Er1EcgFile parseEr1(List<int> raw) => _parse(raw, family: 'er1');

  /// Decode an ER2 file.
  static Er1EcgFile parseEr2(List<int> raw) => _parse(raw, family: 'er2');

  static Er1EcgFile _parse(List<int> raw, {required String family}) {
    // The Android SDK refuses files ≤ 30 bytes (header 10 + trailer 20).
    if (raw.length <= 30) {
      throw ArgumentError(
        'ER1/ER2 file too short: ${raw.length} bytes (need >30)',
      );
    }
    final n = raw.length;
    final waveStart = 10;
    final waveEnd = n - 20; // exclusive end of waveData
    final recordingTime = _u32Le(raw, n - 20);
    final dataCrc = _u16Le(raw, n - 16);
    final magic = _u32Le(raw, n - 4);

    final waveBytes = Uint8List.fromList(raw.sublist(waveStart, waveEnd));
    final sampleCount = waveBytes.length ~/ 2;
    final shorts = Int16List(sampleCount);
    final floats = Float32List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final lo = waveBytes[i * 2] & 0xFF;
      final hi = waveBytes[i * 2 + 1] & 0xFF;
      // Same semantics as `doab.doab(lo, hi)` (signed short LE pair).
      // The RT path also nulls samples flagged with the lead-off
      // sentinel `0x7FFF`, but the on-flash file is post-filter so
      // those values shouldn't appear here.  Preserved verbatim.
      final s = (lo | (hi << 8)).toSigned(16);
      shorts[i] = s;
      floats[i] = s * kEr1EcgMvConversion;
    }

    return Er1EcgFile._(
      family: family,
      fileVersion: raw[0] & 0xFF,
      recordingTime: recordingTime,
      dataCrc: dataCrc,
      magic: magic,
      waveData: waveBytes,
      waveShortData: shorts,
      waveFloatData: floats,
      bytes: Uint8List.fromList(raw),
    );
  }

  /// Recording duration as a [Duration].
  Duration get duration => Duration(seconds: recordingTime);

  /// Number of decoded ECG samples — equivalent to
  /// `waveShortData.length`.
  int get sampleCount => waveShortData.length;

  @override
  String toString() =>
      'Er1EcgFile($family v$fileVersion duration=${recordingTime}s'
      ' samples=$sampleCount magic=0x${magic.toRadixString(16)})';
}

int _u16Le(List<int> b, int o) => (b[o] & 0xFF) | ((b[o + 1] & 0xFF) << 8);

int _u32Le(List<int> b, int o) =>
    (b[o] & 0xFF) |
    ((b[o + 1] & 0xFF) << 8) |
    ((b[o + 2] & 0xFF) << 16) |
    ((b[o + 3] & 0xFF) << 24);
