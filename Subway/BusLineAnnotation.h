//
//  BusLineAnnotation.h
//  Subway
//
//  Created by Mars on 2017/5/5.
//  Copyright © 2017年 Mingjun Ma. All rights reserved.
//

#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>

@interface BusLineAnnotation : BMKPointAnnotation
{
    int _type; ///<0:起点 1：终点 2：公交 3：地铁 4:驾乘
    int _degree;
}

@property (nonatomic) int type;
@property (nonatomic) int degree;


@end
