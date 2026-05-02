// Round-trip tests for the Dart-side file decoders.  Each test
// constructs a minimal byte buffer that matches what the device
// firmware writes to flash, runs the parser, and asserts every
// field is recovered exactly.  The fixtures double as living
// documentation of the on-flash format.

import 'dart:typed_data';

import 'package:flutter_ble_devices/flutter_ble_devices.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a buffer of [length] zeros, then write each `(offset, byte)`
/// in [bytes] over it.  Multi-byte fields are pre-split into their
/// little-endian bytes by the test helpers below.
Uint8List _buf(int length, Map<int, int> bytes) {
  final out = Uint8List(length);
  bytes.forEach((offset, value) {
    out[offset] = value & 0xFF;
  });
  return out;
}

void _writeU16Le(Uint8List buf, int offset, int value) {
  buf[offset]     =  value        & 0xFF;
  buf[offset + 1] = (value >>  8) & 0xFF;
}

void _writeU32Le(Uint8List buf, int offset, int value) {
  buf[offset]     =  value        & 0xFF;
  buf[offset + 1] = (value >>  8) & 0xFF;
  buf[offset + 2] = (value >> 16) & 0xFF;
  buf[offset + 3] = (value >> 24) & 0xFF;
}

void _writeI16Le(Uint8List buf, int offset, int value) {
  // Two's-complement 16-bit encoding.
  final u = value & 0xFFFF;
  buf[offset]     = u        & 0xFF;
  buf[offset + 1] = (u >> 8) & 0xFF;
}

void main() {
  group('EcgDiagnosis', () {
    test('result == 0 → regular sinus rhythm', () {
      final d = EcgDiagnosis.fromInt(0);
      expect(d.isRegular, isTrue);
      expect(d.isPoorSignal, isFalse);
      expect(d.findings, ['Normal sinus rhythm']);
    });

    test('result == -1 → poor signal sentinel', () {
      final d = EcgDiagnosis.fromInt(-1);
      expect(d.isPoorSignal, isTrue);
      expect(d.isRegular, isFalse);
      expect(d.findings, ['Poor signal']);
    });

    test('result == -2 → lead-off sentinel', () {
      final d = EcgDiagnosis.fromInt(-2);
      expect(d.isLeadOff, isTrue);
      expect(d.findings, ['Lead off']);
    });

    test('bit-mask: fast HR + irregular + AFib', () {
      // Bit 0 (fastHr) | Bit 2 (irregular) | Bit 5 (AFib)
      final v = 0x01 | 0x04 | 0x20;
      final d = EcgDiagnosis.fromInt(v);
      expect(d.isFastHr, isTrue);
      expect(d.isIrregular, isTrue);
      expect(d.isFibrillation, isTrue);
      expect(d.isSlowHr, isFalse);
      expect(d.isPvcs, isFalse);
      expect(d.findings, [
        'Fast heart rate',
        'Irregular rhythm',
        'Atrial fibrillation',
      ]);
    });

    test('all twelve bits decode independently', () {
      const masks = <int, String>{
        0x001: 'Fast heart rate',
        0x002: 'Slow heart rate',
        0x004: 'Irregular rhythm',
        0x008: 'PVCs',
        0x010: 'Heart pause',
        0x020: 'Atrial fibrillation',
        0x040: 'Wide QRS (>120 ms)',
        0x080: 'Prolonged QTc (>450 ms)',
        0x100: 'Short QTc (<300 ms)',
      };
      masks.forEach((bit, label) {
        final d = EcgDiagnosis.fromInt(bit);
        expect(d.findings, [label], reason: 'bit 0x${bit.toRadixString(16)}');
      });
    });

    test('fromLeBytes decodes the same way as fromInt', () {
      // 0x00000005 little-endian = fastHr + irregular
      final d = EcgDiagnosis.fromLeBytes([0x05, 0x00, 0x00, 0x00]);
      expect(d.isFastHr, isTrue);
      expect(d.isIrregular, isTrue);
    });
  });

  group('Bp2BpFile (fileType=1)', () {
    test('parses every documented field', () {
      // 19-byte BP record. Build it field-by-field.
      final raw = _buf(19, {
        0: 0x05, // fileVersion
        1: 0x01, // fileType (BP)
        17: 72,  // pr
        18: 0x01, // result → arrhythmia true
      });
      // measureTime: 2024-05-01 09:30:15 UTC = 1714555815
      // (file stores localTime = UTC + tz offset, so to get UTC=raw - tz)
      // Use a fixed tzOffset for deterministic asserts.
      const tzOffset = Duration(hours: 0);
      const measureTimeRaw = 1714555815;
      _writeU32Le(raw, 2,  measureTimeRaw);
      _writeU16Le(raw, 11, 128); // sys
      _writeU16Le(raw, 13,  82); // dia
      _writeU16Le(raw, 15,  98); // mean

      final f = Bp2File.parse(raw, timezoneOffset: tzOffset) as Bp2BpFile;
      expect(f.fileVersion, 5);
      expect(f.fileType, 1);
      expect(f.measureTimeRaw, measureTimeRaw);
      expect(f.measureTime, measureTimeRaw); // tz=0 ⇒ same value
      expect(f.sys, 128);
      expect(f.dia, 82);
      expect(f.mean, 98);
      expect(f.pr, 72);
      expect(f.result, 1);
      expect(f.arrhythmia, isTrue);
    });

    test('arrhythmia false when result byte is 0', () {
      final raw = _buf(19, {0: 1, 1: 1, 17: 70});
      _writeU32Le(raw, 2, 1714555815);
      _writeU16Le(raw, 11, 120);
      _writeU16Le(raw, 13, 80);
      _writeU16Le(raw, 15, 95);

      final f = Bp2File.parse(raw, timezoneOffset: Duration.zero) as Bp2BpFile;
      expect(f.arrhythmia, isFalse);
      expect(f.result, 0);
    });

    test('throws on truncated buffer', () {
      expect(() => Bp2File.parse([0x01, 0x01]), throwsArgumentError);
    });

    test('measureTime subtracts tz offset', () {
      final raw = _buf(19, {0: 1, 1: 1});
      _writeU32Le(raw, 2,  10_000);
      _writeU16Le(raw, 11, 100);
      _writeU16Le(raw, 13,  60);
      _writeU16Le(raw, 15,  73);
      // tzOffset = +5:30 → expect measureTime = 10000 - 19800 = -9800
      final f = Bp2File.parse(raw,
          timezoneOffset: const Duration(hours: 5, minutes: 30)) as Bp2BpFile;
      expect(f.measureTimeRaw, 10_000);
      expect(f.measureTime, 10_000 - 19_800);
    });
  });

  group('Bp2EcgFile (fileType=2)', () {
    test('parses header + waveform', () {
      // Header (48 bytes) + 4 fake samples (8 bytes wave).
      final raw = _buf(48 + 8, {
        0: 7,    // fileVersion
        1: 2,    // fileType (ECG)
        28: 1,   // connectCable
      });
      _writeU32Le(raw, 2,  1714555815);  // measureTime
      _writeU32Le(raw, 10,         30);  // recordingTime (s)
      _writeU32Le(raw, 16, 0x00000005);  // result: fastHr + irregular
      _writeU16Le(raw, 20,         88);  // hr
      _writeU16Le(raw, 22,        100);  // qrs
      _writeU16Le(raw, 24,          2);  // pvcs
      _writeU16Le(raw, 26,        420);  // qtc
      // 4 ECG samples: 100, -100, 200, -32768 (extreme negative)
      _writeI16Le(raw, 48,    100);
      _writeI16Le(raw, 50,   -100);
      _writeI16Le(raw, 52,    200);
      _writeI16Le(raw, 54, -32768);

      final f = Bp2File.parse(raw, timezoneOffset: Duration.zero)
          as Bp2EcgFile;
      expect(f.fileType, 2);
      expect(f.fileVersion, 7);
      expect(f.recordingTime, 30);
      expect(f.duration, const Duration(seconds: 30));
      expect(f.hr, 88);
      expect(f.qrs, 100);
      expect(f.pvcs, 2);
      expect(f.qtc, 420);
      expect(f.connectCable, isTrue);
      expect(f.result, 5);
      expect(f.diagnosis.isFastHr, isTrue);
      expect(f.diagnosis.isIrregular, isTrue);
      expect(f.diagnosis.isPvcs, isFalse);
      // Waveform
      expect(f.waveShortData, [100, -100, 200, -32768]);
      expect(f.waveFloatData[0], closeTo(100 * kBp2EcgMvConversion, 1e-7));
      expect(f.waveFloatData[3], closeTo(-32768 * kBp2EcgMvConversion, 1e-3));
      expect(f.waveData.length, 8);
    });

    test('signed-32 sentinel diagnosis values pass through', () {
      final raw = _buf(48 + 4, {0: 1, 1: 2});
      // result == -1 (poor signal): 0xFFFFFFFF in u32
      _writeU32Le(raw, 16, 0xFFFFFFFF);
      _writeU32Le(raw, 10, 1);
      final f = Bp2File.parse(raw, timezoneOffset: Duration.zero)
          as Bp2EcgFile;
      expect(f.result, -1);
      expect(f.diagnosis.isPoorSignal, isTrue);
    });

    test('throws on truncated header', () {
      expect(() => Bp2File.parse(_buf(40, {0: 1, 1: 2})), throwsArgumentError);
    });

    test('unknown fileType returns Bp2UnknownFile', () {
      final raw = _buf(40, {0: 9, 1: 9});
      final f = Bp2File.parse(raw);
      expect(f, isA<Bp2UnknownFile>());
      expect(f.fileType, 9);
    });
  });

  group('Er1EcgFile / Er2EcgFile', () {
    /// Build a synthetic ER1/ER2 file with `n` waveform samples.
    Uint8List buildEr1(int sampleCount,
        {int recordingTime = 60, int dataCrc = 0x1234, int magic = 0xDEADBEEF,
         List<int>? samples}) {
      final waveBytes = sampleCount * 2;
      final buf = Uint8List(10 + waveBytes + 20);
      buf[0] = 0x01; // fileVersion
      // Skip reserved header (1..10).
      // Waveform.
      final s = samples ?? List.generate(sampleCount, (i) => i - sampleCount ~/ 2);
      for (var i = 0; i < sampleCount; i++) {
        _writeI16Le(buf, 10 + i * 2, s[i]);
      }
      // Trailer
      _writeU32Le(buf, buf.length - 20, recordingTime);
      _writeU16Le(buf, buf.length - 16, dataCrc);
      _writeU32Le(buf, buf.length - 4,  magic);
      return buf;
    }

    test('round-trips fileVersion / recordingTime / crc / magic', () {
      final buf = buildEr1(100,
          recordingTime: 30, dataCrc: 0xABCD, magic: 0xCAFEBABE);
      final f = Er1EcgFile.parseEr1(buf);
      expect(f.family, 'er1');
      expect(f.fileVersion, 1);
      expect(f.recordingTime, 30);
      expect(f.duration, const Duration(seconds: 30));
      expect(f.dataCrc, 0xABCD);
      expect(f.magic, 0xCAFEBABE);
      expect(f.sampleCount, 100);
    });

    test('decodes signed-LE samples and applies mV conversion', () {
      final buf = buildEr1(4, samples: [0, 1000, -1000, 32767]);
      final f = Er1EcgFile.parseEr2(buf);
      expect(f.family, 'er2');
      expect(f.waveShortData, [0, 1000, -1000, 32767]);
      expect(f.waveFloatData[0], 0.0);
      expect(f.waveFloatData[1], closeTo(1000 * kEr1EcgMvConversion, 1e-6));
      expect(f.waveFloatData[2], closeTo(-1000 * kEr1EcgMvConversion, 1e-6));
      expect(f.waveFloatData[3], closeTo(32767 * kEr1EcgMvConversion, 1e-3));
    });

    test('throws when file too short (<= 30 bytes)', () {
      // 30 bytes is rejected (header 10 + trailer 20 → 0 wave samples).
      final tooSmall = Uint8List(30);
      expect(() => Er1EcgFile.parseEr1(tooSmall), throwsArgumentError);
    });

    test('parseEr2 yields family=er2', () {
      final buf = buildEr1(50);
      final f = Er1EcgFile.parseEr2(buf);
      expect(f.family, 'er2');
    });
  });

  group('FileReadCompleteEvent.decoded', () {
    test('dispatches BP2 → Bp2BpFile', () {
      final raw = Uint8List(19);
      raw[0] = 1; raw[1] = 1; raw[17] = 60;
      _writeU32Le(raw, 2, 1714555815);
      _writeU16Le(raw, 11, 120);
      _writeU16Le(raw, 13, 80);
      _writeU16Le(raw, 15, 93);
      final ev = FileReadCompleteEvent(
        model: 19,
        deviceFamily: 'bp2',
        fileName: 'foo.bin',
        content: raw,
      );
      expect(ev.decoded, isA<Bp2BpFile>());
    });

    test('dispatches er1 / er2 → Er1EcgFile', () {
      final buf = Uint8List(40); // header(10) + 10 samples(20) + trailer(20)
      buf[0] = 1;
      _writeU32Le(buf, buf.length - 20, 5);
      _writeU16Le(buf, buf.length - 16, 0);
      _writeU32Le(buf, buf.length - 4,  0);
      final ev1 = FileReadCompleteEvent(
        model: 7, deviceFamily: 'er1', fileName: 'a', content: buf,
      );
      expect(ev1.decoded, isA<Er1EcgFile>());
      expect((ev1.decoded as Er1EcgFile).family, 'er1');

      final ev2 = FileReadCompleteEvent(
        model: 11, deviceFamily: 'er2', fileName: 'a', content: buf,
      );
      expect((ev2.decoded as Er1EcgFile).family, 'er2');
    });

    test('returns null for unknown family or empty content', () {
      final ev = FileReadCompleteEvent(
        model: 0, deviceFamily: 'oxy', fileName: '', content: Uint8List(0),
      );
      expect(ev.decoded, isNull);
      final ev2 = FileReadCompleteEvent(
        model: 0, deviceFamily: 'pf10aw1', fileName: '',
        content: Uint8List.fromList([1, 2, 3]),
      );
      expect(ev2.decoded, isNull);
    });
  });
}
