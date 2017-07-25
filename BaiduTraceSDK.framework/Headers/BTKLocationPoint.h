//
//  BTKLocationPoint.h
//  BaiduTraceSDK
//
//  Created by Daniel Bey on 2017年03月27日.
//  Copyright © 2017 Daniel Bey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BTKTypes.h"

/// 轨迹点的基类
/**
 轨迹点的基类
 */
@interface BTKLocationPoint : NSObject

/**
 轨迹点的坐标
 */
@property (nonatomic, assign) CLLocationCoordinate2D location;

/**
 轨迹点的坐标类型
 */
@property (nonatomic, assign) BTKCoordType coordType;

/**
 轨迹点的定位时间
 */
@property (nonatomic, assign) UInt64 loctime;

@end
