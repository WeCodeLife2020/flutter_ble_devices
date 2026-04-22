//
//  ICCoordData.h
//  ICDeviceManager
//
//  Created by Symons on 2018/8/10.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Coordinate data.
 */
@interface ICCoordData : NSObject

/**
 Measurement timestamp (seconds).
 */
@property (nonatomic, assign) NSUInteger time;

/**
 X coordinate.
 */
@property (nonatomic, assign) NSInteger x;

/**
 Y coordinate.
 */
@property (nonatomic, assign) NSInteger y;

@end
