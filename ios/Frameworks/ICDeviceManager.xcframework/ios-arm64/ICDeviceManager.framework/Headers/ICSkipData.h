//
//  ICSkipData.h
//  ICDeviceManager
//
//  Created by Symons on 2019/10/19.
//  Copyright © 2019 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICConstant.h"

NS_ASSUME_NONNULL_BEGIN



/**
 * Interval-skipping data.
 */
@interface ICSkipInterruptData : NSObject

/**
 * Index.
 */
@property (nonatomic, assign) NSUInteger index;

/**
 * Rest time.
 */
@property (nonatomic, assign) NSUInteger rest_time;


/**
 * Duration.
 */
@property (nonatomic, assign) NSUInteger time;

/**
 * Number of jumps.
 */
@property (nonatomic, assign) NSUInteger skip_count;


/**
 * Calories burned.
 */
@property (nonatomic, assign) double calories_burned;

/**
 * Average frequency.
 */
@property (nonatomic, assign) NSUInteger avg_freq;

/**
 * Trip-rope (stumble) count.
 */
@property (nonatomic, assign) NSUInteger freq_count;

@end



/**
 * Rope-skipping frequency entry.
 */
@interface ICSkipFreqData : NSObject

/**
 * Duration.
 */
@property (nonatomic, assign) NSUInteger duration;

/**
 * Count.
 */
@property (nonatomic, assign) NSUInteger skip_count;

@end



/**
 * Rope-skipping data.
 */
@interface ICSkipData : NSObject


    /**
     Whether the reading is stable.
     */
    @property (nonatomic, assign) BOOL isStabilized;

    /**
     Node ID.
     */
    @property (nonatomic, assign) NSUInteger nodeId;
    /**
     Node battery level.
     */
    @property (nonatomic, assign) NSUInteger battery;
    /**
     Node info.
     */
    @property (nonatomic, assign) NSUInteger nodeInfo;

    /**
     Rope-skipping status. Not available on every device; currently only S2.
     */
    @property (nonatomic, assign) ICSkipStatus status;

    /**
     Node MAC address.
     */
    @property (nonatomic, strong) NSString* nodeMac;


    /**
     * Number of groups (S2 only).
     */
    @property (nonatomic, assign) NSUInteger setting_group;

    /**
     * Configured rest interval (S2 only).
     */
    @property (nonatomic, assign) NSUInteger setting_rest_time;
    
    /**
     * Measurement timestamp in seconds.
     */
    @property (nonatomic, assign) NSUInteger time;
    
    /**
     * Rope-skipping mode.
     */
    @property (nonatomic, assign) ICSkipMode mode;
    
    /**
     * Configured parameter.
     */
    @property (nonatomic, assign) NSUInteger  setting;
    
    /**
     * Elapsed time used for skipping.
     */
    @property (nonatomic, assign) NSUInteger elapsed_time;

    /**
     * Actual time spent skipping. Not supported on every device.
     */
    @property (nonatomic, assign) NSUInteger actual_time;


    /**
     * Number of jumps.
     */
    @property (nonatomic, assign) NSUInteger skip_count;
    
    /**
     * Average frequency.
     */
    @property (nonatomic, assign) NSUInteger  avg_freq;

    /**
     * Current speed (S2 only).
     */
    @property (nonatomic, assign) NSUInteger  cur_speed;

    /**
     * Fastest frequency.
     */
    @property (nonatomic, assign) NSUInteger fastest_freq;

    /**
     * Calories burned.
     */
    @property (nonatomic, assign) double calories_burned;

    /**
     * Fat-burn efficiency.
     */
    @property (nonatomic, assign) double fat_burn_efficiency;

    /**
     * Total trip-rope (stumble) count.
     */
    @property (nonatomic, assign) NSUInteger freq_count;

    /**
     * Maximum consecutive jumps.
     */
    @property (nonatomic, assign) NSUInteger most_jump;

    /**
     * Heart rate.
     */
    @property (nonatomic, assign) NSUInteger hr;

    /**
     * Rope-skipping frequency samples.
     */
    @property (nonatomic, strong) NSArray<ICSkipFreqData *> *freqs;

    /**
     * Interval-skipping data.
     */
    @property (nonatomic, strong) NSArray<ICSkipInterruptData *> *interrupts;

@end

NS_ASSUME_NONNULL_END
