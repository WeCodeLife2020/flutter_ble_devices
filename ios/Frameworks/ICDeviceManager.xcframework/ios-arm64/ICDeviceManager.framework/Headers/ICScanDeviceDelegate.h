//
//  ICScanDeviceDelegate.h
//  ICDeviceManager
//

#import <Foundation/Foundation.h>

@class ICScanDeviceInfo;

/**
 Delegate for scan-result callbacks.
 */
@protocol ICScanDeviceDelegate <NSObject>

/**
 Scan-result callback.

 @param deviceInfo The scanned device info.
 */
- (void)onScanResult:(ICScanDeviceInfo *)deviceInfo;

@end
