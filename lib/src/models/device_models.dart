/// Lepu SDK device model constants.
///
/// Values mirror `com.lepu.blepro.objs.Bluetooth.MODEL_*` in the Lepu AAR
/// (dumped from `lepu-blepro-1.2.0.aar`). The iOS `VTMDeviceTypeMapper`
/// emits the same integers so `device.model` is identical on both
/// platforms — you can hard-code these in a `switch` without branching
/// on `Platform.isAndroid`.
///
/// Use them when calling [BluetodevController.scan] with model filters
/// or when checking which device type was discovered.
class DeviceModels {
  DeviceModels._();

  // ═══════════════════════════════════════════════════════════════
  // ECG — ER1 family
  // ═══════════════════════════════════════════════════════════════
  static const int er1 = 7; // MODEL_ER1
  static const int er1N = 16; // MODEL_ER1_N
  static const int hhm1 = 73; // MODEL_HHM1
  /// Legacy "ER1S" firmware (no dash in advertised name).
  static const int er1sLegacy = 127; // MODEL_ER1S
  /// Current "ER1-S" hardware revision.
  static const int er1S = 145; // MODEL_ER1_S
  static const int er1H = 146; // MODEL_ER1_H
  static const int er1W = 147; // MODEL_ER1_W
  /// ER1-L (covers ER1-LW consumer rebrand — same Lepu model id).
  static const int er1L = 148; // MODEL_ER1_L / ER1-LW

  static const List<int> er1Family = [
    er1,
    er1N,
    hhm1,
    er1sLegacy,
    er1S,
    er1H,
    er1W,
    er1L,
  ];

  // ═══════════════════════════════════════════════════════════════
  // ECG — ER2 family
  // ═══════════════════════════════════════════════════════════════
  static const int er2 = 33; // MODEL_ER2
  static const int duoek = 8; // MODEL_DUOEK
  static const int lpEr2 = 77; // MODEL_LP_ER2
  static const int lepuEr2 = 168; // MODEL_LEPU_ER2
  static const int hhm2 = 74; // MODEL_HHM2
  static const int hhm3 = 75; // MODEL_HHM3
  static const int er2S = 149; // MODEL_ER2_S

  static const List<int> er2Family = [
    er2,
    duoek,
    lpEr2,
    lepuEr2,
    hhm2,
    hhm3,
    er2S,
  ];

  // ═══════════════════════════════════════════════════════════════
  // ECG — ER3 / M-series
  // ═══════════════════════════════════════════════════════════════
  static const int er3 = 95; // MODEL_ER3
  static const int m12 = 152; // MODEL_M12
  static const int m5 = 176; // MODEL_M5
  static const int lepod = 96; // MODEL_LEPOD
  static const int lepodPro = 151; // MODEL_LEPOD_PRO

  static const List<int> er3Family = [er3, m12, m5, lepod, lepodPro];

  /// All ECG models
  static const List<int> allEcg = [...er1Family, ...er2Family, ...er3Family];

  // ═══════════════════════════════════════════════════════════════
  // Oximeter — O2Ring family (legacy 0xAA UART protocol)
  // ═══════════════════════════════════════════════════════════════
  static const int o2ring = 4; // MODEL_O2RING
  static const int o2m = 25; // MODEL_O2M
  static const int babyO2 = 13; // MODEL_BABYO2
  static const int babyO2N = 29; // MODEL_BABYO2N
  static const int checkO2 = 1; // MODEL_CHECKO2
  static const int sleepO2 = 3; // MODEL_SLEEPO2
  static const int snoreO2 = 2; // MODEL_SNOREO2
  static const int wearO2 = 5; // MODEL_WEARO2
  static const int sleepU = 6; // MODEL_SLEEPU
  static const int oxylink = 10; // MODEL_OXYLINK
  static const int kidsO2 = 11; // MODEL_KIDSO2
  static const int oxyfit = 20; // MODEL_OXYFIT
  static const int oxyring = 63; // MODEL_OXYRING
  static const int bbsmS1 = 64; // MODEL_BBSM_S1
  static const int bbsmS2 = 65; // MODEL_BBSM_S2
  static const int oxyu = 69; // MODEL_OXYU
  static const int aiS100 = 72; // MODEL_AI_S100
  static const int cmring = 66; // MODEL_CMRING
  static const int o2mWps = 101; // MODEL_O2M_WPS
  static const int oxyfitWps = 112; // MODEL_OXYFIT_WPS
  static const int kidsO2Wps = 113; // MODEL_KIDSO2_WPS
  static const int bbsmS3 = 199; // MODEL_BBSM_S3
  static const int o2ringRe = 217; // MODEL_O2RING_RE
  static const int o2ringF = 203; // MODEL_O2RINGF

  static const List<int> o2RingFamily = [
    o2ring,
    o2m,
    babyO2,
    babyO2N,
    checkO2,
    sleepO2,
    snoreO2,
    wearO2,
    sleepU,
    oxylink,
    kidsO2,
    oxyfit,
    oxyring,
    bbsmS1,
    bbsmS2,
    oxyu,
    aiS100,
    cmring,
    o2mWps,
    oxyfitWps,
    kidsO2Wps,
    bbsmS3,
    o2ringRe,
    o2ringF,
  ];

  // ═══════════════════════════════════════════════════════════════
  // Oximeter — wearable O2Ring S (structured URAT protocol)
  // ═══════════════════════════════════════════════════════════════
  static const int o2ringS = 124; // MODEL_O2RING_S

  // ═══════════════════════════════════════════════════════════════
  // Oximeter — PC60FW / PF10 family
  // ═══════════════════════════════════════════════════════════════
  static const int pc60fw = 30; // MODEL_PC60FW
  static const int pc60nw = 60; // MODEL_PC_60NW
  static const int pc60nw1 = 36; // MODEL_PC_60NW_1
  static const int pc66b = 42; // MODEL_PC66B
  static const int pf10 = 57; // MODEL_PF_10
  static const int pf20 = 58; // MODEL_PF_20
  static const int oxysmart = 14; // MODEL_OXYSMART
  static const int pod2b = 35; // MODEL_POD2B
  static const int pod1w = 37; // MODEL_POD_1W
  static const int s5w = 70; // MODEL_S5W

  static const List<int> pc60fwFamily = [
    pc60fw,
    pc60nw,
    pc60nw1,
    pc66b,
    pf10,
    pf20,
    oxysmart,
    pod2b,
    pod1w,
    s5w,
  ];

  // ═══════════════════════════════════════════════════════════════
  // Oximeter — PF10AW / PF10AW1 / PF10AW_1 / PF10BW / PF10BWS family
  // ═══════════════════════════════════════════════════════════════
  static const int pf10Aw = 85; // MODEL_PF_10AW
  static const int pf10Aw1 = 86; // MODEL_PF_10AW1 (older w/o underscore)
  static const int pf10AwU1 = 123; // MODEL_PF_10AW_1 (newer w/ underscore)
  static const int pf10Bw = 87; // MODEL_PF_10BW
  static const int pf10Bw1 = 88; // MODEL_PF_10BW1
  static const int pf10Bws = 126; // MODEL_PF_10BWS
  static const int sa10AwPu = 133; // MODEL_SA10AW_PU
  static const int pf10BwVe = 134; // MODEL_PF10BW_VE

  static const List<int> pf10Family = [
    pf10Aw,
    pf10Aw1,
    pf10AwU1,
    pf10Bw,
    pf10Bw1,
    pf10Bws,
    sa10AwPu,
    pf10BwVe,
  ];

  /// All oximeter models
  static const List<int> allOximeter = [
    ...o2RingFamily,
    o2ringS,
    ...pc60fwFamily,
    ...pf10Family,
  ];

  // ═══════════════════════════════════════════════════════════════
  // Blood Pressure — BP2 family
  // ═══════════════════════════════════════════════════════════════
  static const int bp2 = 19; // MODEL_BP2
  static const int bp2a = 23; // MODEL_BP2A
  static const int bp2t = 31; // MODEL_BP2T
  static const int bp2w = 32; // MODEL_BP2W
  static const int lpBp2w = 52; // MODEL_LP_BP2W

  static const List<int> bp2Family = [bp2, bp2a, bp2t, bp2w, lpBp2w];

  // ═══════════════════════════════════════════════════════════════
  // Blood Pressure — BP3 family
  // ═══════════════════════════════════════════════════════════════
  static const int bp3a = 118; // MODEL_BP3A
  static const int bp3b = 119; // MODEL_BP3B
  static const int bp3c = 155; // MODEL_BP3C

  static const List<int> bp3Family = [bp3a, bp3b, bp3c];

  // ═══════════════════════════════════════════════════════════════
  // Blood Pressure — Others
  // ═══════════════════════════════════════════════════════════════
  static const int bpm = 26; // MODEL_BPM
  /// MODEL_AIRBP in the Lepu SDK — driven by `VTAirBPPacket` on iOS
  /// (Nordic UART protocol, no external SDK).
  static const int airbp = 153; // MODEL_AIRBP

  /// All blood pressure models
  static const List<int> allBp = [...bp2Family, ...bp3Family, bpm, airbp];

  // ═══════════════════════════════════════════════════════════════
  // Scales
  // ═══════════════════════════════════════════════════════════════
  /// Custom id used by [LescaleController] (flutter_blue_plus driven path
  /// — not from the Lepu SDK). Kept here so both scale paths can be
  /// filtered together in a UI model switch.
  static const int lescaleF4 = 9999;

  /// Baby patch — BBSM-P1 (URAT path).
  static const int bbsmBs1 = 185; // MODEL_BBSM_BS1
}
