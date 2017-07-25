//
//  BTKTrackAction.h
//  BaiduTraceSDK
//
//  Created by Daniel Bey on 2017年04月11日.
//  Copyright © 2017 Daniel Bey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTKQueryTrackLatestPointRequest.h"
#import "BTKQueryTrackDistanceRequest.h"
#import "BTKQueryHistoryTrackRequest.h"
#import "BTKTrackDelegate.h"

/// 轨迹纠偏与里程计算操作类
/**
 轨迹纠偏与里程计算
 */
@interface BTKTrackAction : NSObject

/**
 轨迹相关操作的全局访问点

 @return 单例对象
 */
+(BTKTrackAction *)sharedInstance;

/**
 查询某终端实体的实时位置

 @param request 查询请求对象
 @param delegate 操作结果的回调对象
 */
-(void)queryTrackLatestPointWith:(BTKQueryTrackLatestPointRequest *)request delegate:(id<BTKTrackDelegate>)delegate;

/**
 查询某终端实体在一段时间内的里程

 @param request 查询请求对象
 @param delegate 操作结果的回调对象
 */
-(void)queryTrackDistanceWith:(BTKQueryTrackDistanceRequest *)request delegate:(id<BTKTrackDelegate>)delegate;

/**
 查询某终端实体在一段时间内的轨迹

 @param request 查询请求对象
 @param delegate 操作结果的回调对象
 */
-(void)queryHistoryTrackWith:(BTKQueryHistoryTrackRequest *)request delegate:(id<BTKTrackDelegate>)delegate;

@end
