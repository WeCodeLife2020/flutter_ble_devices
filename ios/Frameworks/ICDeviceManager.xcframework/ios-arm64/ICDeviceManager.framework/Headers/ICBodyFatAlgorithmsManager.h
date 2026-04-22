//
//  ICBodyFatAlgorithms.h
//  ICDeviceManager
//
//  Created by Symons on 2018/9/26.
//  Copyright (c) 2018 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ICUserInfo;
@class ICWeightData;

/**
 Body-fat algorithm protocol.
 */
@protocol ICBodyFatAlgorithmsManager <NSObject>

/**
 Re-compute body-fat data.

 @param weightData Weight data (the payload the SDK originally delivered).
 @param userInfo   User info.
 @return           Re-computed weight data.
 */
- (ICWeightData *)reCalcBodyFatWithWeightData:(ICWeightData *)weightData userInfo:(ICUserInfo *)userInfo;

@end
