//
//  ICScaleSoundSettingData.h
//  ICDeviceManager
//
//  Created by Guobin Zheng on 2023/4/20.
//  Copyright © 2023 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICScaleSoundSettingData : NSObject

/// Language type for the scale. Pick a value from the list returned by the device.
@property (nonatomic, assign) NSUInteger soundLanguageCode;
/// Scale volume. 0: mute, 1-30: low, 31-70: medium, 71-100: high.
@property (nonatomic, assign) NSUInteger soundVolume;
/// Voice-broadcast switch.
@property (nonatomic, assign) BOOL soundBroadcastOn;
/// Sound-effects switch.
@property (nonatomic, assign) BOOL soundEffectsOn;
/// List of languages the scale supports.
@property (nonatomic, strong) NSArray<NSNumber *> *listSoundSupportLanguage;

@end

NS_ASSUME_NONNULL_END
