//
//  ICSkipSoundSettingData.h
//  ICDeviceManager
//
//  Created by icomon on 2022/3/16.
//  Copyright © 2022 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICSkipSoundSettingData : NSObject

/// Voice switch.
@property (nonatomic, assign) BOOL soundOn;
/// Voice type.
@property (nonatomic, assign) ICSkipSoundType soundType;
/// Volume level.
@property (nonatomic, assign) NSUInteger soundVolume;
/// Full-score switch.
@property (nonatomic, assign) BOOL fullScoreOn;
/// Full-score BPM target.
@property (nonatomic, assign) NSUInteger fullScoreBPM;
/// Voice-interval mode.
@property (nonatomic, assign) ICSkipSoundMode soundMode;
/// Mode parameter.
@property (nonatomic, assign) NSUInteger modeParam;
/// Whether the skipping rope auto-stops its audio. YES: once the app sends Start the device stays silent. NO: both device and app play audio.
@property (nonatomic, assign) BOOL isAutoStop;

/// Voice-assistant switch. Only supported on S2.
@property (nonatomic, assign) BOOL assistantOn;
/// Metronome switch. Only supported on S2.
@property (nonatomic, assign) BOOL bpmOn;
/// Vibration switch. Only supported on S2.
@property (nonatomic, assign) BOOL vibrationOn;
/// Heart-rate high-alarm switch. Only supported on S2.
@property (nonatomic, assign) BOOL hrMonitorOn;






@end

NS_ASSUME_NONNULL_END
