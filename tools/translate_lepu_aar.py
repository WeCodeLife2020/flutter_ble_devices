#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Translate every Chinese string literal inside the Lepu Bluetooth-SDK AAR
(android/libs/lepu-blepro-*.aar) into English.

The Lepu SDK ships ~186 Chinese strings embedded in Log.d / toString /
error-message calls. None of them are flow-control (nothing in Lepu or
in this repo compares Chinese literals against runtime strings), so we
can safely rewrite the `CONSTANT_Utf8` entries inside each .class file
without breaking behaviour.

How it works
------------
A JVM .class constant pool is just a sequence of self-describing entries.
`CONSTANT_Utf8_info` looks like:

    u1 tag  = 1
    u2 length
    u1 bytes[length]

Nothing else in the class file references constant-pool entries by byte
offset -- they are all referenced by 1-based index. Changing the byte
length of a Utf8 entry is therefore safe: no attribute_length or code
offset needs updating.

We parse the CP, replace every Utf8 containing CJK with its English
equivalent (adjusting the `length` field), and re-emit the class.

Run:
    python3 tools/translate_lepu_aar.py

The script patches the AAR in place and creates a .orig backup the first
time it runs.
"""
from __future__ import annotations

import io
import os
import re
import shutil
import struct
import sys
import tempfile
import zipfile
from pathlib import Path
from typing import Iterable

REPO = Path(__file__).resolve().parent.parent
AAR = REPO / "android" / "libs" / "lepu-blepro-1.2.0.aar"
BACKUP = AAR.with_suffix(AAR.suffix + ".orig")

CJK = re.compile(r"[\u4e00-\u9fff]")

# ---------------------------------------------------------------------------
# Translations
# ---------------------------------------------------------------------------
#
# Each key is the exact Chinese-containing string literal that appears in the
# Lepu SDK's compiled .class files; the value is the English replacement.
# The script will raise if it encounters a Chinese literal that isn't in this
# map so that future SDK updates don't silently leave Chinese behind.
TRANSLATIONS: dict[str, str] = {
    # --- toString() helpers (Bp2/ER1/ER2/Pc100/Sp20 data classes) ---------
    # These Chinese strings show up inside Kotlin triple-quoted multi-line
    # toString(): they embed the property name on its own indented line. We
    # therefore have to match (and replace) the exact multi-line literal,
    # newlines included.
    "\n                \n                hrIvState(心率报警,0\uff1a未达到报警条件 1\uff1a达到报警条件 2\uff1a达到报警条件\uff0c但是盒子不报警) : ":
        "\n                \n                hrIvState(HR alarm, 0: below threshold; 1: at threshold; 2: at threshold but device silent) : ",
    "\n                \n                invalidIvState(无效值报警,0\uff1a未达到报警条件 1\uff1a达到报警条件 2\uff1a达到报警条件\uff0c但是盒子不报警) : ":
        "\n                \n                invalidIvState(invalid-value alarm, 0: below threshold; 1: at threshold; 2: at threshold but device silent) : ",
    "\n                \n                spo2IvState(血氧报警,0\uff1a未达到报警条件 1\uff1a达到报警条件 2\uff1a达到报警条件\uff0c但是盒子不报警) : ":
        "\n                \n                spo2IvState(SpO2 alarm, 0: below threshold; 1: at threshold; 2: at threshold but device silent) : ",
    "\n                \n                vectorIvState(体动报警,0\uff1a未达到报警条件 1\uff1a达到报警条件 2\uff1a达到报警条件\uff0c但是盒子不报警) : ":
        "\n                \n                vectorIvState(motion alarm, 0: below threshold; 1: at threshold; 2: at threshold but device silent) : ",
    "\n                0\uff1a准备阶段 1\uff1a测量准备阶段 2\uff1a测量中 3\uff1a测量结束\n                sensorState : ":
        "\n                0: ready; 1: prep; 2: measuring; 3: done\n                sensorState : ",
    "\n                0\uff1a导联脱落\uff0c未放手指\uff0c1\uff1a正常状态\uff0c2\uff1a探头拔出\uff0c3\uff1a传感器或探头故障\n                spo2 : ":
        "\n                0: lead off / no finger; 1: normal; 2: probe removed; 3: sensor or probe fault\n                spo2 : ",
    "\n                0\uff1a正常使用\uff0c1\uff1a充电中\uff0c2\uff1a充满\uff0c3\uff1a低电量 <10%\n                batteryPercent(电池电量百分比) : ":
        "\n                0: normal; 1: charging; 2: full; 3: low battery <10%\n                batteryPercent(battery %) : ",
    "\n                0\uff1a清醒 1\uff1a浅睡 2\uff1a深睡\n            ":
        "\n                0: awake; 1: light sleep; 2: deep sleep\n            ",
    "\n                awakeDuration(清醒时长) : ":
        "\n                awakeDuration(awake duration) : ",
    "\n                deepDuration(深睡时长) : ":
        "\n                deepDuration(deep-sleep duration) : ",
    "\n                flag(标志参数, 0:脉搏音标志) : ":
        "\n                flag(flag parameter, 0: pulse-tone flag) : ",
    "\n                lightDuration(浅睡时长): ":
        "\n                lightDuration(light-sleep duration): ",
    "\n                motion(体动) : ":
        "\n                motion(motion level) : ",
    "\n                quiet(安静值) : ":
        "\n                quiet(quiet level) : ",
    "\n                sleepState(睡眠状态) : ":
        "\n                sleepState(sleep state) : ",
    "\n                totalDuration(睡眠总时长) : ":
        "\n                totalDuration(total sleep duration) : ",
    "\n                wakeCount(清醒次数) : ":
        "\n                wakeCount(awake count) : ",
    "\n                充电状态\uff080\uff1a没有充电 1\uff1a充电中 2\uff1a充电完成\uff09\n                pi = ":
        "\n                charge state (0: none; 1: charging; 2: full)\n                pi = ",
    "\n                工作状态\uff080\uff1a导联脱落 1\uff1a导联连上 其他\uff1a异常\uff09\n                sleepState = ":
        "\n                work state (0: lead off; 1: lead on; other: abnormal)\n                sleepState = ",
    " 秒\n            leadSize : ":
        " s\n            leadSize : ",

    # --- file-read / OTA logging -----------------------------------------
    "  文件名：": "  filename: ",
    " 将要读取文件 ": " about to read file ",
    " 将要读取文件fileName: ": " about to read file fileName: ",
    " 已下载完成": " download finished",
    " 秒": " s",
    ", 总数": ", total",
    ", 文件大小：": ", file size: ",
    ", 读文件中：": ", reading file: ",
    ", 读文件失败：": ", read file failed: ",
    ", 读文件完成: ": ", read file complete: ",

    # --- BleCmd command-description logs (Bp2/ER1/ER2/Oxy/Pc300/Glu) -----
    ",BP_ERROR_RESULT 血压测量出现的错误结果 => success ":
        ",BP_ERROR_RESULT BP measurement error result => success ",
    ",BP_MODE 血压模式命令 => success ":
        ",BP_MODE BP mode command => success ",
    ",BP_RESULT 血压测量结果 => success ":
        ",BP_RESULT BP measurement result => success ",
    ",BP_START 血压开始测量命令 => success ":
        ",BP_START BP start-measurement command => success ",
    ",BP_STOP 血压停止测量命令 => success ":
        ",BP_STOP BP stop-measurement command => success ",
    ",BS_UNIT 控制血糖显示单位(仅适用百捷) => success ":
        ",BS_UNIT set glucose display unit (Bioland only) => success ",
    ",CHOL_RESULT 总胆固醇 => success ":
        ",CHOL_RESULT total cholesterol => success ",
    ",DEVICE_INFO 查询产品版本及电量等级 => success ":
        ",DEVICE_INFO query firmware version and battery level => success ",
    ",DEVICE_INFO_2 查询版本及电量等级 => success ":
        ",DEVICE_INFO_2 query version and battery level => success ",
    ",DEVICE_INFO_4 查询版本及电量等级 => success ":
        ",DEVICE_INFO_4 query version and battery level => success ",
    ",DISABLE_WAVE 禁止主动发送数据 => success ":
        ",DISABLE_WAVE disable active data upload => success ",
    ",ECG_DATA_DIGIT 设置心电数据位数 => success ":
        ",ECG_DATA_DIGIT set ECG data bit width => success ",
    ",ECG_RT_STATE 心电查询工作状态 => success ":
        ",ECG_RT_STATE query ECG working state => success ",
    ",ECG_START 心电开始测量命令 => success ":
        ",ECG_START ECG start-measurement command => success ",
    ",ECG_STOP 心电停止测量命令 => success ":
        ",ECG_STOP ECG stop-measurement command => success ",
    ",ENABLE_WAVE 允许主动发送数据 => success ":
        ",ENABLE_WAVE enable active data upload => success ",
    ",GET_CONFIG 查询配置信息 => ":
        ",GET_CONFIG query configuration => ",
    ",GET_DEVICE_ID 查询产品 ID => success ":
        ",GET_DEVICE_ID query product ID => success ",
    ",GET_DEVICE_NAME 查询产品名称 => success ":
        ",GET_DEVICE_NAME query product name => success ",
    ",GET_DEVICE_NAME 查询产品名称 device name null":
        ",GET_DEVICE_NAME query product name, device name null",
    ",GET_TEMP_MODE 查询体温计参数 => success ":
        ",GET_TEMP_MODE query thermometer parameters => success ",
    ",GET_VERSION 心电查询版本 => success ":
        ",GET_VERSION query ECG version => success ",
    ",GLU_RESULT 血糖 => success ":
        ",GLU_RESULT glucose => success ",
    ",KEY_BOOT => success 设备开机":
        ",KEY_BOOT => success device power-on",
    ",KEY_HISTORY_END => success 同步数据完成":
        ",KEY_HISTORY_END => success history sync complete",
    ",OXY_RT_STATE 血氧上传状态数据包 => success ":
        ",OXY_RT_STATE oximetry state upload => success ",
    ",SET_CONFIG 设置配置信息 => ":
        ",SET_CONFIG set configuration => ",
    ",SET_DEVICE_ID 设置产品 ID => success ":
        ",SET_DEVICE_ID set product ID => success ",
    ",SET_TEMP_MODE 配置体温计参数 => success ":
        ",SET_TEMP_MODE configure thermometer parameters => success ",
    ",SET_TIME 设置时间 => success ":
        ",SET_TIME set time => success ",
    ",TEMP_RESULT 体温测量结果 => success ":
        ",TEMP_RESULT temperature result => success ",
    ",TOKEN_0X32 心电波形上传数据 => success ":
        ",TOKEN_0X32 ECG waveform upload => success ",
    ",TOKEN_0X33 心电结果上传参数 => success ":
        ",TOKEN_0X33 ECG result parameters upload => success ",
    ",TOKEN_0X34 设备硬件增益 => success ":
        ",TOKEN_0X34 device hardware gain => success ",
    ",TOKEN_0X42 血压当前值和心跳信息 => success ":
        ",TOKEN_0X42 BP live value and heartbeat info => success ",
    ",TOKEN_0X52 血氧上传波形数据包 => success ":
        ",TOKEN_0X52 oximetry waveform upload => success ",
    ",TOKEN_0X53 血氧上传参数数据包 => success ":
        ",TOKEN_0X53 oximetry parameter upload => success ",
    ",TOKEN_0X70 体温开始测量命令 => success ":
        ",TOKEN_0X70 temperature start-measurement command => success ",
    ",TOKEN_0X73 血糖结果 => success ":
        ",TOKEN_0X73 glucose result => success ",
    ",TOKEN_0XD0 上传PC_300SNT 关机命令信息 => success ":
        ",TOKEN_0XD0 PC_300SNT shutdown-command info upload => success ",
    ",TOKEN_0XE3 设置下位机血糖仪类型 => ":
        ",TOKEN_0XE3 set glucometer device type => ",
    ",TOKEN_0XE4 查询下位机当前配置的血糖仪类型 => ":
        ",TOKEN_0XE4 query glucometer device type => ",
    ",TOKEN_0XE5 清除血糖历史数据 => success ":
        ",TOKEN_0XE5 clear glucose history => success ",
    ",UA_RESULT 尿酸 => success ":
        ",UA_RESULT uric acid => success ",

    # --- calendar short-names --------------------------------------------
    "-星期": "-DOW",

    # --- BleServiceHelper / scan / reconnect logs ------------------------
    "BIOL 已取消订阅蓝牙 model":
        "BIOL unsubscribed from BLE model",
    "BIOL 开始订阅蓝牙 model":
        "BIOL subscribing to BLE model",
    "checkModel, 无效model：":
        "checkModel, invalid model: ",
    "content 长度不匹配: ":
        "content length mismatch: ",
    "crc 正确: ":
        "crc ok: ",
    "crc 错误: ":
        "crc error: ",
    "filterResult 未扫描到指定model的设备":
        "filterResult no device for the requested model",
    "hasUnConnected  已初始化interface的设备: model = ":
        "hasUnConnected interface-initialised device: model = ",
    "hasUnConnected 没有未连接的设备 ":
        "hasUnConnected no disconnected devices ",
    "index > fileSize. 文件下载完成":
        "index > fileSize. file download finished",
    "into reconnect 名称重连单个model":
        "into reconnect: name-based reconnect (single model)",
    "into reconnect 名称重连多个model":
        "into reconnect: name-based reconnect (multi-model)",
    "into reconnectByAddress 地址重连单个model":
        "into reconnectByAddress: address-based reconnect (single model)",
    "into reconnectByAddress 地址重连多个model":
        "into reconnectByAddress: address-based reconnect (multi-model)",
    "into startScan 扫描单个model":
        "into startScan: single-model scan",
    "into startScan 扫描多个model":
        "into startScan: multi-model scan",
    "isScanDefineDevice 未扫描到指定蓝牙名的设备":
        "isScanDefineDevice no device for the requested BT name",
    "isScanDefineDevice 未扫描到指定蓝牙地址的设备":
        "isScanDefineDevice no device for the requested BT address",
    "onScanResult 取消定时重扫机制":
        "onScanResult cancelled periodic rescan",
    "onScanResult 外发sdk未能识别model的信息 ":
        "onScanResult SDK could not identify model info ",
    "onScanResult 扫描有结果返回":
        "onScanResult scan returned a result",
    "raw 文件 model=":
        "raw file model=",
    "reconnectByAddress 有未连接的设备":
        "reconnectByAddress has disconnected devices",
    "reconnectByName 有未连接的设备....":
        "reconnectByName has disconnected devices....",

    # --- generic status / enums ------------------------------------------
    "不存在": "does not exist",
    "不满30s不分析; ": "less than 30s, not analysed; ",
    "从重连名单中移除 ": "removed from reconnect list ",
    "传感器震荡异常": "sensor oscillation abnormal",
    "低电量": "low battery",
    "佩带过松": "strap too loose",
    "佩带过紧": "strap too tight",
    "保存路径有误": "save path invalid",
    "信号饱和，由于运动或其他原因使信号幅度太大(检查患者状况，使患者手臂停止运动，保持静止重新进行测量)":
        "signal saturated: motion or other cause made the signal amplitude too large (check the patient, keep the arm still, stay motionless and retake the measurement)",
    "停搏; ": "asystole; ",
    "充满": "fully charged",
    "充电中": "charging",
    "删除路径有误": "delete path invalid",
    "动感模式": "dynamic mode",
    "历史界面状态": "history-screen state",
    "压力超过上限": "pressure above upper limit",
    "发现需要重连的设备....去连接 model = ":
        "found a device needing reconnect .... connecting, model = ",
    "存在": "exists",
    "导联一直脱落; ": "lead constantly detached; ",
    "将要读取文件 ": "about to read file ",
    "已经取消/暂停下载 isCancelRF = ":
        "download cancelled / paused isCancelRF = ",
    "已经存入的fileLength = ":
        "already-written fileLength = ",
    "弱信号，可能是测量对象脉搏太弱或袖带过松(可能是患者脉搏太弱或袖带过松，检查患者情况，重新将袖带安放在一个合适的部位。若故障继续存在，联系制造商更新袖带)":
        "weak signal, possibly because the subject's pulse is too weak or the cuff is too loose (check the patient, re-place the cuff on an appropriate site; if the fault persists contact the manufacturer to replace the cuff)",
    "待机界面/时间界面": "standby / time screen",
    "心室早搏; ": "premature ventricular contraction; ",
    "成功将要移除一个订阅者": "successfully removing a subscriber",
    "成功添加了一个订阅者": "successfully added a subscriber",
    "房颤; ": "atrial fibrillation; ",
    "捶击模式": "pound mode",
    "文件": "file",
    "时间设置状态": "time-setting state",
    "普通模式": "normal mode",
    "标定数据异常或未标定": "calibration data invalid or uncalibrated",
    "检测不到脉搏": "pulse not detected",
    "检测不到足够的心跳或算不出血压":
        "not enough heartbeats detected, unable to compute BP",
    "检测到动作，不分析; ": "motion detected, not analysed; ",
    "模块忙或测量正在进行中": "module busy or measurement in progress",
    "正常使用": "normal use",
    "正常心电; ": "normal ECG; ",
    "气压错误，可能是阀门无法正常打开(环境大气压力不正确，确认所处环境符合产品的规格，是否有特殊原因影响环境压力)":
        "pressure error, possibly because the valve cannot open (ambient pressure is incorrect; confirm the environment meets the product spec and check for any unusual pressure source)",
    "气管被堵住": "air tube blocked",
    "没有未连接和已连接中的设备": "no disconnected or connected devices",
    "泄气心率闪烁状态": "deflating heart-rate blink state",
    "波形质量差，或者导联一直脱落等算法无法分析; ":
        "poor waveform quality or lead detached: algorithm cannot analyse; ",
    "活力模式": "vitality mode",
    "测量加压状态": "measurement inflation state",
    "测量时压力波动大": "large pressure fluctuation during measurement",
    "测量时未佩戴袖带(按正确的方式佩戴袖带进行测量)":
        "cuff not worn during measurement (wear the cuff correctly and retake the measurement)",
    "测量模块故障或未接入": "measurement module faulty or disconnected",
    "测量状态": "measurement state",
    "测量结束": "measurement finished",
    "测量结束状态": "measurement-finished state",
    "测量结果异常": "measurement result abnormal",
    "测量超时(可能病人测量过程运动导致，保持静止后重新测量)":
        "measurement timed out (possibly caused by patient motion during measurement; stay still and retake)",
    "漏气，可能是阀门或气路中漏气(袖带未按正确方法佩戴、没有连接好气路存在漏气情况，参考使用说明正确佩戴袖带，若故障继续存在，联系制造商进行维修)":
        "air leak, possibly from the valve or the pneumatic path (cuff not fitted correctly or pneumatic path leaking; consult the instructions to fit the cuff correctly; if the fault persists contact the manufacturer for service)",
    "漏气，在漏气检测中，发现系统气路漏气(检查袖带，重新测量，若故障仍存在，联系制造商进行维修)":
        "air leak detected in the system pneumatic path (check the cuff and retake; if the fault persists contact the manufacturer for service)",
    "省心模式": "easy mode",
    "系统错误，开机后，充气泵、A/D采样、压力传感器出错，或者软件运行指针出错(重新开机启动血压测量)":
        "system error: after power-on the pump, ADC sampling or pressure sensor failed, or a software pointer fault occurred (power-cycle to restart the BP measurement)",
    "自动模式": "auto mode",
    "自检失败(重新开机自检)": "self-test failed (power-cycle to retry)",
    "舒缓模式": "soothing mode",
    "获取到SN: ": "obtained SN: ",
    "袖带压力过大(气路可能发生堵塞，检查气路，然后重新测量)":
        "cuff pressure too high (the pneumatic path may be blocked; inspect it and retake the measurement)",
    "袖带过松或漏气(10 秒内加压不到 30mmHg)":
        "cuff too loose or leaking (inflation did not reach 30 mmHg within 10 s)",
    "袖带过松，可能是袖带缠绕过松，或未接袖带(袖带未按正确方法佩戴、没有连接好气路存在漏气情况，参考使用说明正确佩戴袖带，若故障继续存在，联系制造商进行维修)":
        "cuff too loose: may be wrapped too loosely or not connected (cuff not fitted correctly or pneumatic path leaking; consult the instructions to fit the cuff correctly; if the fault persists contact the manufacturer for service)",
    "设备错误": "device error",
    "设置声音成功": "set sound succeeded",
    "设置夜间区间成功": "set night interval succeeded",
    "设置时间成功": "set time succeeded",
    "设置测量时间成功": "set measurement time succeeded",
    "设置测量间隔成功": "set measurement interval succeeded",
    "请保持安静": "please keep quiet",
    "超范围，可能是测量对象的血压值超过了测量范围(可能是患者的血压值超过了测量范围，保持平静重新测量)":
        "out of range: the subject's BP may be outside the measurement range (stay calm and retake)",
    "过分运动，可能是测量时，信号中含有运动伪差或干扰太多(检查患者状况，使患者手臂停止运动，保持静止重新进行测量)":
        "excessive motion: the signal contains motion artefact or too much interference (check the patient, keep the arm still, stay motionless and retake)",

    # --- ECG diagnosis short strings ------------------------------------
    "HR<50bpm，心率过缓; ":  "HR<50bpm, bradycardia; ",
    "HR>100bpm，心率过速; ": "HR>100bpm, tachycardia; ",
    "QRS>120ms，QRS过宽; ":  "QRS>120ms, wide QRS; ",
    "QTc<300ms，QTc间期缩短; ": "QTc<300ms, shortened QTc; ",
    "QTc>450ms，QTc间期延长; ": "QTc>450ms, prolonged QTc; ",
    "RR间期不规则; ":        "irregular RR interval; ",
    "ST<-0.2mV，ST段压低; ": "ST<-0.2mV, ST depression; ",
    "ST>+0.2mV，ST段抬高; ": "ST>+0.2mV, ST elevation; ",

    # --- stray short field names ----------------------------------------
    "            leadSize : ": "            leadSize : ",  # no change (checked by scan only)
}


# ---------------------------------------------------------------------------
# .class constant-pool parser and patcher
# ---------------------------------------------------------------------------
def _parse_cp(class_bytes: bytes) -> tuple[bytes, int, list[tuple[int, bytes, str | None]], bytes]:
    """
    Returns (prefix_before_cp, cp_count, cp_entries, suffix_after_cp).

    prefix_before_cp: magic (4) + minor (2) + major (2) + cp_count (2)
    cp_entries: list of (tag, full_entry_bytes_minus_tag, utf8_value_or_None)
                For Utf8 entries we keep the decoded string so we can match
                against the translation map.
    suffix_after_cp: everything after the CP (access_flags ... EOF)
    """
    s = io.BytesIO(class_bytes)
    magic = s.read(4)
    if magic != b"\xca\xfe\xba\xbe":
        raise ValueError("not a .class file")
    minor_major = s.read(4)
    (cp_count,) = struct.unpack(">H", s.read(2))
    entries: list[tuple[int, bytes, str | None]] = []
    i = 1
    while i < cp_count:
        (tag,) = struct.unpack(">B", s.read(1))
        if tag == 1:  # Utf8
            (length,) = struct.unpack(">H", s.read(2))
            data = s.read(length)
            try:
                value = data.decode("utf-8")
            except UnicodeDecodeError:
                # Java's "modified UTF-8" allows non-standard encodings for
                # surrogates and NUL. We don't touch those; only translate
                # strictly-UTF-8 entries, which is where CJK lives anyway.
                value = None
            entries.append((tag, struct.pack(">H", length) + data, value))
        elif tag in (3, 4):               # Integer, Float
            entries.append((tag, s.read(4), None))
        elif tag in (5, 6):               # Long, Double (occupy 2 slots)
            entries.append((tag, s.read(8), None))
            entries.append((tag, b"", None))  # placeholder for the second slot
            i += 1
        elif tag == 7:                    # Class
            entries.append((tag, s.read(2), None))
        elif tag == 8:                    # String
            entries.append((tag, s.read(2), None))
        elif tag == 9:                    # Fieldref
            entries.append((tag, s.read(4), None))
        elif tag == 10:                   # Methodref
            entries.append((tag, s.read(4), None))
        elif tag == 11:                   # InterfaceMethodref
            entries.append((tag, s.read(4), None))
        elif tag == 12:                   # NameAndType
            entries.append((tag, s.read(4), None))
        elif tag == 15:                   # MethodHandle
            entries.append((tag, s.read(3), None))
        elif tag == 16:                   # MethodType
            entries.append((tag, s.read(2), None))
        elif tag == 17:                   # Dynamic
            entries.append((tag, s.read(4), None))
        elif tag == 18:                   # InvokeDynamic
            entries.append((tag, s.read(4), None))
        elif tag == 19:                   # Module
            entries.append((tag, s.read(2), None))
        elif tag == 20:                   # Package
            entries.append((tag, s.read(2), None))
        else:
            raise ValueError(f"unknown constant-pool tag {tag}")
        i += 1
    prefix = magic + minor_major + struct.pack(">H", cp_count)
    suffix = s.read()
    return prefix, cp_count, entries, suffix


def _rebuild_class(
    prefix: bytes,
    cp_count: int,
    entries: list[tuple[int, bytes, str | None]],
    suffix: bytes,
) -> bytes:
    out = bytearray(prefix)
    prev_is_long_or_double = False
    for tag, body, _ in entries:
        if prev_is_long_or_double:
            prev_is_long_or_double = False
            continue
        out.append(tag)
        out.extend(body)
        if tag in (5, 6):
            prev_is_long_or_double = True
    out.extend(suffix)
    return bytes(out)


def translate_class(class_bytes: bytes, missing: set[str]) -> bytes | None:
    """
    Return the translated .class bytes if we touched it, or None if no
    translation was needed.
    Any Chinese literal not present in TRANSLATIONS is recorded in `missing`.
    """
    prefix, cp_count, entries, suffix = _parse_cp(class_bytes)
    changed = False
    new_entries: list[tuple[int, bytes, str | None]] = []
    for tag, body, value in entries:
        if tag != 1 or value is None or not CJK.search(value):
            new_entries.append((tag, body, value))
            continue
        new_value = TRANSLATIONS.get(value)
        if new_value is None:
            missing.add(value)
            new_entries.append((tag, body, value))
            continue
        new_bytes = new_value.encode("utf-8")
        new_body = struct.pack(">H", len(new_bytes)) + new_bytes
        new_entries.append((tag, new_body, new_value))
        changed = True
    if not changed:
        return None
    return _rebuild_class(prefix, cp_count, new_entries, suffix)


# ---------------------------------------------------------------------------
# AAR patcher
# ---------------------------------------------------------------------------
def translate_aar(aar_path: Path) -> None:
    if not aar_path.exists():
        raise SystemExit(f"{aar_path} not found")
    if not BACKUP.exists():
        shutil.copy2(aar_path, BACKUP)
        print(f"  saved original  → {BACKUP.name}")
    else:
        # Always patch the *original* so re-runs are idempotent.
        shutil.copy2(BACKUP, aar_path)
        print(f"  restored original from  {BACKUP.name}")

    missing: set[str] = set()
    patched_classes = 0
    patched_entries = 0
    with tempfile.TemporaryDirectory() as staging:
        staging = Path(staging)
        with zipfile.ZipFile(aar_path) as src:
            src.extractall(staging)

        # Patch every classes*.jar (AARs can ship a main + library jars).
        for jar_path in sorted(staging.rglob("*.jar")):
            rel = jar_path.relative_to(staging)
            modified = False
            with tempfile.TemporaryDirectory() as jar_staging:
                jar_staging = Path(jar_staging)
                with zipfile.ZipFile(jar_path) as jar_src:
                    info_map = {i.filename: i for i in jar_src.infolist()}
                    members = jar_src.namelist()
                    new_jar = jar_staging / "new.jar"
                    with zipfile.ZipFile(new_jar, "w", zipfile.ZIP_DEFLATED) as jar_dst:
                        for name in members:
                            data = jar_src.read(name)
                            if name.endswith(".class"):
                                try:
                                    translated = translate_class(data, missing)
                                except Exception as e:
                                    print(f"    ! skip {rel}!{name}: {e}")
                                    translated = None
                                if translated is not None:
                                    data = translated
                                    patched_classes += 1
                                    modified = True
                            # Preserve the zip metadata (timestamps etc.)
                            src_info = info_map[name]
                            new_info = zipfile.ZipInfo(filename=name)
                            new_info.date_time = src_info.date_time
                            new_info.external_attr = src_info.external_attr
                            new_info.compress_type = zipfile.ZIP_DEFLATED
                            jar_dst.writestr(new_info, data)
                if modified:
                    shutil.move(str(new_jar), str(jar_path))
                    print(f"  updated {rel}")

        # Rebuild the AAR (itself a zip). Preserve every directory entry
        # that the original AAR carried (even empty ones) so the layout
        # stays byte-for-byte compatible with whatever the original AGP
        # produced.
        with zipfile.ZipFile(BACKUP) as src_aar:
            dir_entries = [n for n in src_aar.namelist() if n.endswith("/")]
        dir_entries_set = set(dir_entries)
        with zipfile.ZipFile(aar_path, "w", zipfile.ZIP_DEFLATED) as out:
            written = set()
            # Files first.
            for p in sorted(staging.rglob("*")):
                if not p.is_file():
                    continue
                rel = p.relative_to(staging)
                out.write(p, arcname=str(rel))
                written.add(str(rel))
            # Then re-add the directory entries from the original AAR.
            for d in dir_entries:
                info = zipfile.ZipInfo(filename=d)
                info.external_attr = 0o40755 << 16  # drwxr-xr-x
                out.writestr(info, b"")

    if missing:
        print()
        print(f"  WARNING: {len(missing)} Chinese literal(s) had no translation:")
        for m in sorted(missing):
            print(f"    | {m!r}")

    print()
    print(f"  patched classes: {patched_classes}")
    # Verify: no Chinese left in any Utf8 entry.
    residue = _count_chinese_in_aar(aar_path)
    if residue:
        print(f"  VERIFY FAIL: {residue} Chinese string(s) still present in the AAR")
        sys.exit(1)
    else:
        print("  verify OK: no Chinese UTF-8 literals remain in the AAR")


def _count_chinese_in_aar(aar_path: Path) -> int:
    count = 0
    with tempfile.TemporaryDirectory() as staging:
        staging = Path(staging)
        with zipfile.ZipFile(aar_path) as src:
            src.extractall(staging)
        for jar in sorted(staging.rglob("*.jar")):
            with zipfile.ZipFile(jar) as jz:
                for name in jz.namelist():
                    if not name.endswith(".class"):
                        continue
                    try:
                        _, _, entries, _ = _parse_cp(jz.read(name))
                    except Exception:
                        continue
                    for tag, _, value in entries:
                        if tag == 1 and value and CJK.search(value):
                            count += 1
    return count


if __name__ == "__main__":
    translate_aar(AAR)
