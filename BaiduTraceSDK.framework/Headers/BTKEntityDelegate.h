//
//  BTKEntityDelegate.h
//  BaiduTraceSDK
//
//  Created by Daniel Bey on 2017年04月11日.
//  Copyright © 2017 Daniel Bey. All rights reserved.
//

#import <Foundation/Foundation.h>

/// entity代理协议，entity相关操作的执行结果，通过本协议中的方法回调
/**
 entity代理协议，entity相关操作的执行结果，通过本协议中的方法回调
 */
@protocol BTKEntityDelegate <NSObject>

@optional
/**
 创建终端实体的回调方法

 @param response 创建结果
 */
-(void)onAddEntity:(NSData *)response;

/**
 删除终端实体的回调方法

 @param response 删除结果
 */
-(void)onDeleteEntity:(NSData *)response;

/**
 更新终端实体的回调方法

 @param response 更新结果
 */
-(void)onUpdateEntity:(NSData *)response;

/**
 查询终端实体的回调方法

 @param response 查询结果
 */
-(void)onQueryEntity:(NSData *)response;

@end
