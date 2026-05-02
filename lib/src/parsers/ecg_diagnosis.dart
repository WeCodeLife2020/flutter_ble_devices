// ECG diagnosis bit-mask decoder, shared by every Lepu family that
// emits a 4-byte "result" field in the recorded file (BP2 family and
// the LpBp2w successor). The bit layout is lifted verbatim from the
// Lepu AAR (`com.lepu.blepro.ext.bp2.EcgDiagnosis` in
// `lepu-blepro-1.2.0.aar`). See also the BP2 `RtEcgResult` emitted on
// the real-time path — it uses the same bit layout.
//
// Wire layout: 4 bytes, interpreted as a little-endian int32. Two
// special sentinel values short-circuit the rest of the flags:
//
//   result == 0  → isRegular         (normal sinus rhythm)
//   result == -1 → isPoorSignal      (lead-off / no signal)
//   result == -2 → isLeadOff         (electrode disconnected)
//
// Otherwise the low nine bits are a bit-mask of concurrent findings.

/// Decoded cardiology flags extracted from a BP2 `EcgFile.result` (or
/// any other Lepu family that stores the same 32-bit bit-mask).
///
/// Each field is a plain boolean matching the corresponding `isXxx`
/// getter on the Lepu Android SDK, so code that previously reflected
/// through the SDK can switch to this class without behaviour change.
class EcgDiagnosis {
  /// Raw little-endian int32 as stored on the device.  `0`, `-1`, and
  /// `-2` are sentinels; all other values are OR-combinations of the
  /// bit-flag constants below.
  final int raw;

  final bool isRegular;
  final bool isPoorSignal;
  final bool isLeadOff;
  final bool isFastHr;
  final bool isSlowHr;
  final bool isIrregular;
  final bool isPvcs;
  final bool isHeartPause;
  final bool isFibrillation;
  final bool isWideQrs;
  final bool isProlongedQtc;
  final bool isShortQtc;

  const EcgDiagnosis._({
    required this.raw,
    required this.isRegular,
    required this.isPoorSignal,
    required this.isLeadOff,
    required this.isFastHr,
    required this.isSlowHr,
    required this.isIrregular,
    required this.isPvcs,
    required this.isHeartPause,
    required this.isFibrillation,
    required this.isWideQrs,
    required this.isProlongedQtc,
    required this.isShortQtc,
  });

  /// Decode a 32-bit diagnosis value. Matches
  /// `com.lepu.blepro.ext.bp2.EcgDiagnosis(int)` byte-for-byte.
  factory EcgDiagnosis.fromInt(int value) {
    // Normalise to signed 32-bit so the `-1` / `-2` sentinels compare
    // correctly on 64-bit Dart ints.
    final v = value.toSigned(32);
    if (v == 0) {
      return EcgDiagnosis._(
        raw: v,
        isRegular: true, isPoorSignal: false, isLeadOff: false,
        isFastHr: false, isSlowHr: false, isIrregular: false,
        isPvcs: false, isHeartPause: false, isFibrillation: false,
        isWideQrs: false, isProlongedQtc: false, isShortQtc: false,
      );
    }
    if (v == -1) {
      return EcgDiagnosis._(
        raw: v,
        isRegular: false, isPoorSignal: true, isLeadOff: false,
        isFastHr: false, isSlowHr: false, isIrregular: false,
        isPvcs: false, isHeartPause: false, isFibrillation: false,
        isWideQrs: false, isProlongedQtc: false, isShortQtc: false,
      );
    }
    if (v == -2) {
      return EcgDiagnosis._(
        raw: v,
        isRegular: false, isPoorSignal: false, isLeadOff: true,
        isFastHr: false, isSlowHr: false, isIrregular: false,
        isPvcs: false, isHeartPause: false, isFibrillation: false,
        isWideQrs: false, isProlongedQtc: false, isShortQtc: false,
      );
    }
    return EcgDiagnosis._(
      raw: v,
      isRegular: false,
      isPoorSignal: false,
      isLeadOff: false,
      isFastHr:       (v & 0x001) != 0,
      isSlowHr:       (v & 0x002) != 0,
      isIrregular:    (v & 0x004) != 0,
      isPvcs:         (v & 0x008) != 0,
      isHeartPause:   (v & 0x010) != 0,
      isFibrillation: (v & 0x020) != 0,
      isWideQrs:      (v & 0x040) != 0,
      isProlongedQtc: (v & 0x080) != 0,
      isShortQtc:     (v & 0x100) != 0,
    );
  }

  /// Decode from the four raw bytes at `bytes[offset..offset+4]`.
  factory EcgDiagnosis.fromLeBytes(List<int> bytes, [int offset = 0]) {
    if (bytes.length - offset < 4) {
      return EcgDiagnosis.fromInt(0);
    }
    final v = (bytes[offset]     & 0xFF)        |
              ((bytes[offset + 1] & 0xFF) << 8) |
              ((bytes[offset + 2] & 0xFF) << 16) |
              ((bytes[offset + 3] & 0xFF) << 24);
    return EcgDiagnosis.fromInt(v);
  }

  /// True iff no abnormality was flagged.  Equivalent to the Android
  /// SDK's `isRegular` getter; included here as a convenience alias.
  bool get isNormal => isRegular;

  /// All flags that fired, as a human-readable list (in English).  The
  /// Lepu SDK ships a localised Chinese message in `resultMess`; this
  /// variant is chosen so the plugin's users can render it anywhere
  /// without pulling in the vendor SDK.
  List<String> get findings {
    if (isRegular)      return const ['Normal sinus rhythm'];
    if (isPoorSignal)   return const ['Poor signal'];
    if (isLeadOff)      return const ['Lead off'];
    final out = <String>[];
    if (isFastHr)       out.add('Fast heart rate');
    if (isSlowHr)       out.add('Slow heart rate');
    if (isIrregular)    out.add('Irregular rhythm');
    if (isPvcs)         out.add('PVCs');
    if (isHeartPause)   out.add('Heart pause');
    if (isFibrillation) out.add('Atrial fibrillation');
    if (isWideQrs)      out.add('Wide QRS (>120 ms)');
    if (isProlongedQtc) out.add('Prolonged QTc (>450 ms)');
    if (isShortQtc)     out.add('Short QTc (<300 ms)');
    return out;
  }

  @override
  String toString() =>
      'EcgDiagnosis(raw=0x${raw.toUnsigned(32).toRadixString(16)} '
      '${findings.join(", ")})';
}
