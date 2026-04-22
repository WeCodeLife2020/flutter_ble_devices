//
//  ICScaleLightSettingData.h
//  ICDeviceManager
//
//  Created by Guobin Zheng on 2024/5/27.
//  Copyright © 2024 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ICScaleLightSettingData : NSObject

/*
 Light-setting operation. 0: set, 1: get.
*/
@property (nonatomic, assign) NSInteger operateType;
/*
 Light number. Default: 0.
*/
@property (nonatomic, assign) NSInteger lightNum;
/*
 Light on/off switch.
*/
@property (nonatomic, assign) BOOL lightOn;
/*
 Light brightness. Currently the scale supports 50 and 100.
*/
@property (nonatomic, assign) NSInteger brightness;

/*
 Light RGB colour. Red (255,0,0), Orange (255,165,0), Yellow (255,255,0), Green (0,255,0), Blue (0,0,255), Cyan (0,255,255), Deep Purple (139,0,255).
*/
@property (nonatomic, assign) NSUInteger r;

@property (nonatomic, assign) NSUInteger g;

@property (nonatomic, assign) NSUInteger b;

@end

NS_ASSUME_NONNULL_END
