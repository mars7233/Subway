//
//  ViewController.h
//  Subway
//
//  Created by Mars on 2017/5/2.
//  Copyright © 2017年 Mingjun Ma. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+Rotate.h"
#import "JFLocation.h"
#import "JFAreaDataManager.h"
#import "JFCityViewController.h"
#import "BaiduTraceSDK/BaiduTraceSDK.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Search/BMKRouteSearch.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import <BaiduMapAPI_Radar/BMKRadarComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Search/BMKRouteSearchOption.h>
#import <BaiduMapAPI_Cloud/BMKCloudSearchComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import "BaiduTraceSDK/BaiduTraceSDK.h"
#import "BusLineAnnotation.h"
#import "SportNode.h"
#import "RouteAnnotation.h"
#import "Subway-Swift.h"


@interface ViewController : UIViewController<BMKMapViewDelegate,BMKPoiSearchDelegate,BMKLocationServiceDelegate,BMKRouteSearchDelegate,BTKTraceDelegate,BTKTrackDelegate,BTKEntityDelegate,BMKBusLineSearchDelegate,JFLocationDelegate, UIPickerViewDelegate,UIPickerViewDataSource,UITextFieldDelegate> {
    
    __weak IBOutlet UINavigationItem *naviTitle;
    IBOutlet BMKMapView* _mapView;
    __weak IBOutlet UIBarButtonItem *areaChoose;
    IBOutlet UITextField* _startAddrText;
    IBOutlet UITextField* _endAddrText;
    __weak IBOutlet UISwitch *transportSelector;
    __weak IBOutlet UITextField *busLine;
    __weak IBOutlet UIButton *searchButton;
    
//    infomationView
    __weak IBOutlet UILabel *_travelDistance;
    __weak IBOutlet UILabel *_travelTime;
    
    __weak IBOutlet UILabel *stateText;
    __weak IBOutlet UIButton *starServiceButton;
    __weak IBOutlet UIButton *stopServiceButton;
    
    __weak IBOutlet UIView *infomationView;
    __weak IBOutlet UILabel *currentStationText;
    __weak IBOutlet UILabel *nextStationText;
    __weak IBOutlet UIButton *hideInformationButton;
    
    
    
//    pickerView
   __weak IBOutlet UIPickerView *pickerView;
    __weak IBOutlet UIView *pickerViewBackground;
  
    

    
    NSMutableArray* _busPoiArray;
    //百度
    BMKRouteSearch* _routesearch;
    BMKPoiSearch* _poisearch;
    BMKBusLineSearch* _buslinesearch;
    BMKPointAnnotation* _annotation;
    BMKLocationService* _locService;
    BMKPolygon *pathPloygon;
    BMKPointAnnotation *sportAnnotation;
    BMKAnnotationView *sportAnnotationView;
    
    
    CLLocation *currentLocation;
    BOOL currentTransport;//当前乘坐的交通工具，1为地铁，0为公交
    BOOL informationViewStatus;//informationView的使用的情况，1为使用中，0为不使用
    BOOL pickerViewStatus;//pickerView的使用情况，1为使用，0为不使用
    BOOL pickerViewSelect;//pickerView的使用场景，0为起点，1位终点
    NSMutableArray *sportNodes;//轨迹点
    NSInteger sportNodeNum;//轨迹点数
    NSInteger currentIndex;//当前结点
    NSInteger currentStationIndex;
    SportNode *currentNode;
    NSNumber *durationMinute;
    NSNumber *durationDistance;
    
    
    NSInteger state;
    NSTimer *timer;
    StatusJudgement *statusJudgement;
    NSMutableArray *busStations;
}
- (IBAction)areaChoose:(id)sender;

- (IBAction)buslineSelect:(id)sender;
- (IBAction)startStationSelect:(id)sender;
- (IBAction)endStationSelect:(id)sender;


- (IBAction)onClickNewBusSearch:(id)sender;
- (IBAction)stopService:(id)sender;
- (IBAction)startService:(id)sender;
- (IBAction)hideInformationButton:(id)sender;
- (IBAction)transportSelect:(id)sender;
- (IBAction)selectStation:(id)sender;

/** 城市定位管理器*/
@property (nonatomic, strong) JFLocation *locationManager;
/** 城市数据管理器*/
@property (nonatomic, strong) JFAreaDataManager *manager;

@property (nonatomic, strong) NSDictionary *pickerData;
@property (nonatomic, strong) NSArray *pickerLineData;
@property (nonatomic, strong) NSArray *pickerStationData;

@property (nonatomic, strong) NSDictionary *pickerSubwayData;
@property (nonatomic, strong) NSArray *pickerSubwayLineData;
@property (nonatomic, strong) NSArray *pickerSubwayStationData;

@property (nonatomic, strong) NSDictionary *pickerBusData;
@property (nonatomic, strong) NSArray *pickerBusLineData;
@property (nonatomic, strong) NSArray *pickerBusStationData;

@end

