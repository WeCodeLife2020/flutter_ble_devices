//
//  ICElectrodeData.h
//  ICDeviceManager
//
//  Created by Symons on 2019/3/12.
//  Copyright © 2019 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 Electrode-by-electrode weight data.
 */
@interface ICElectrodeData : NSObject

/**
 Top-left electrode weight (kg).
 */
@property (nonatomic, assign) NSUInteger weightLT_kg;

/**
 Bottom-left electrode weight (kg).
 */
@property (nonatomic, assign) NSUInteger weightLB_kg;

/**
 Top-right electrode weight (kg).
 */
@property (nonatomic, assign) NSUInteger weightRT_kg;

/**
 Bottom-right electrode weight (kg).
 */
@property (nonatomic, assign) NSUInteger weightRB_kg;


@end

