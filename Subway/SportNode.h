//
//  SportNode.h
//  Subway
//
//  Created by Mars on 2017/5/5.
//  Copyright © 2017年 Mingjun Ma. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <Foundation/Foundation.h>

@interface SportNode : NSObject

//经纬度
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
//方向（角度）
@property (nonatomic, assign) CGFloat angle;
//距离
@property (nonatomic, assign) CGFloat distance;
//速度
@property (nonatomic, assign) CGFloat speed;

@end
