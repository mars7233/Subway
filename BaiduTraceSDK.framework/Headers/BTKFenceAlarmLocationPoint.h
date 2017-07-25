//
//  BTKFenceAlarmLocationPoint.h
//  BaiduTraceSDK
//
//  Created by Daniel Bey on 2017年03月27日.
//  Copyright © 2017 Daniel Bey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTKLocationPoint.h"

/// 地理围栏报警信息中轨迹点信息类
@interface BTKFenceAlarmLocationPoint : BTKLocationPoint

/**
 该轨迹点的定位精度
 */
@property (nonatomic, assign) double radius;
/**
 该轨迹点上传到服务端的时间
 */
@property (nonatomic, assign) UInt64 createTime;

@end
