//
//  ViewController.m
//  Subway
//
//  Created by Mars on 2017/5/2.
//  Copyright © 2017年 Mingjun Ma. All rights reserved.
//

#import "ViewController.h"

#define MYBUNDLE_NAME @ "mapapi.bundle"
#define MYBUNDLE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: MYBUNDLE_NAME]
#define MYBUNDLE [NSBundle bundleWithPath: MYBUNDLE_PATH]
#define KCURRENTCITYINFODEFAULTS [NSUserDefaults standardUserDefaults]

static NSUInteger serviceID = 140050;
static NSString *AK = @"CUrcO69UZjCTNehrDmvD0Z2p37V6B00E";
static NSString *mcode = @"mars.Subway";
static NSString *entityName = @"Subway";

@interface ViewController ()
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    //设备适配
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0))
    {
        //self.edgesForExtendedLayout=UIRectEdgeNone;
        self.navigationController.navigationBar.translucent = NO;
    }
    //  设置 NavigationBar 背景颜色&title 颜色
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:20/255.0 green:155/255.0 blue:213/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName,nil]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    //
    //    UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"注意！" message:@"即将到站，清注意下车！" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"好的", nil];
    //    [alertview show];
    //
    naviTitle.title = @"地铁";
    currentTransport = 1;
    
    busLine.delegate = self;
    _startAddrText.delegate = self;
    _endAddrText.delegate = self;
    
    busLine.inputView = [[UIView alloc] init ];
    busLine.inputView.hidden = YES;
    _startAddrText.inputView = [[UIView alloc] init];
    _startAddrText.inputView.hidden = YES;
    _endAddrText.inputView = [[UIView alloc] init];
    _endAddrText.inputView.hidden = YES;
    
    busLine.tag = 0;
    _startAddrText.tag = 1;
    _endAddrText.tag = 2;
    
//    UI位置初始化
    [self.view sendSubviewToBack:infomationView];
    [self.view sendSubviewToBack:pickerViewBackground];
    
    _mapView.frame = CGRectMake(0, 104, 414, 630);
    infomationView.frame = CGRectMake(0,-32, 414,128);
    pickerViewBackground.frame = CGRectMake(0,-189,414,175);
    
    //    选择器初始化
    pickerView.dataSource = self;
    pickerView.delegate = self;
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *plistPath = [bundle pathForResource:@"SubwayList" ofType:@"plist"];
    //    获取全部数据
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    self.pickerSubwayData = dict;
    //    地铁线路数据
    self.pickerSubwayLineData = [self.pickerSubwayData allKeys];
    //    默认取出第一个线路所有数据
    NSString *selectedStation = [self.pickerSubwayLineData objectAtIndex:0];
    self.pickerSubwayStationData = [self.pickerSubwayData objectForKey:selectedStation];

    
//  区域选择器初始化
    self.locationManager = [[JFLocation alloc] init];
    _locationManager.delegate = self;
    stopServiceButton.enabled = false;
    [self mapDidLoad];
    
    currentLocation = [[CLLocation alloc] init];
    currentStationIndex = 0;
    informationViewStatus = 0;
    state = 0;
    
    
    
}

- (JFAreaDataManager *)manager {
    if (!_manager) {
        _manager = [JFAreaDataManager shareManager];
        [_manager areaSqliteDBData];
    }
    return _manager;
}

-(void)subwayStatusJudge{
    NSInteger stationCount = [busStations count];
    dispatch_queue_t queue = dispatch_queue_create("mars.refresh", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        state = [statusJudgement statusJudges];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(state == 0){
                stateText.text = @"正常行驶";
                NSLog(@"地铁正常行驶");
            }else if (state == 1){
                stateText.text = @"离站加速";
                NSLog(@"地铁离站加速");
            }else if(state == 2){
                stateText.text = @"到站减速";
                NSLog(@"地铁到站减速");
            }
        });
        NSLog(@"总共%ld站",stationCount);
    });
    
    NSLog(@"%ld",state);
}

-(void)busStatusJudge{
    NSDictionary* currentStation = [busStations objectAtIndex:currentStationIndex];
    if((currentStationIndex+1 < [busStations count]-1)){
        NSDictionary* nextStation = [busStations objectAtIndex:currentStationIndex+1];
        currentStationText.text = currentStation[@"station"];
        nextStationText.text = nextStation[@"station"];
        
        BMKMapPoint currentPoint = BMKMapPointForCoordinate(currentLocation.coordinate);
        BMKMapPoint nextPoint = BMKMapPointForCoordinate(CLLocationCoordinate2DMake([nextStation[@"latitude"] floatValue], [nextStation[@"longitude"] floatValue]));
        CLLocationDistance distance = BMKMetersBetweenMapPoints(currentPoint,nextPoint);
        NSLog(@"当前经纬度纬度：%f，经度：%f",currentLocation.coordinate.latitude,currentLocation.coordinate.longitude);
        NSLog(@"下一站经纬度纬度：%f，经度：%f",[nextStation[@"latitude"] floatValue],[nextStation[@"longitude"] floatValue]);
        
        if(distance >=10){
            stateText.text = [NSString stringWithFormat:@"距离%@还有%.2f公里",nextStation[@"station"],distance/1000];
        }else if(distance<10){
            stateText.text = [NSString stringWithFormat:@"即将到达%@",nextStation[@"station"]];
            currentStationIndex = currentStationIndex+1;
        }
    }else if(currentStationIndex+1 == [busStations count]-1){
        NSDictionary* nextStation = [busStations objectAtIndex:currentStationIndex+1];
        currentStationText.text = currentStation[@"station"];
        nextStationText.text = nextStation[@"station"];
        
        BMKMapPoint currentPoint = BMKMapPointForCoordinate(currentLocation.coordinate);
        BMKMapPoint nextPoint = BMKMapPointForCoordinate(CLLocationCoordinate2DMake([nextStation[@"latitude"] floatValue], [nextStation[@"longitude"] floatValue]));
        CLLocationDistance distance = BMKMetersBetweenMapPoints(currentPoint,nextPoint);
        NSLog(@"当前经纬度纬度：%f，经度：%f",currentLocation.coordinate.latitude,currentLocation.coordinate.longitude);
        NSLog(@"下一站经纬度纬度：%f，经度：%f",[nextStation[@"latitude"] floatValue],[nextStation[@"longitude"] floatValue]);
        
        if(distance >=10){
            stateText.text = [NSString stringWithFormat:@"距离终点站还有%.2f公里",distance/1000];
        }else if(distance<10){
            stateText.text = [NSString stringWithFormat:@"即将到达终点站%@",nextStation[@"station"]];
        }
        
    }
}


-(void)pickerView{
    if(currentTransport == 1){
        [self pickSubwayData];
        [pickerView reloadAllComponents];
    }else{
        [self pickBusData];
        [pickerView reloadAllComponents];
    }
}

-(void)pickSubwayData{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *plistPath = [bundle pathForResource:@"SubwayList" ofType:@"plist"];
    //    获取全部数据
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    self.pickerSubwayData = dict;
    //    地铁线路数据
    self.pickerSubwayLineData = [self.pickerSubwayData allKeys];
    //    默认取出第一个线路所有数据
    NSString *selectedStation = [self.pickerSubwayLineData objectAtIndex:0];
    self.pickerSubwayStationData = [self.pickerSubwayData objectForKey:selectedStation];
}

-(void)pickBusData{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *plistPath = [bundle pathForResource:@"BusList" ofType:@"plist"];
    //    获取全部数据
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    self.pickerBusData = dict;
    //    地铁线路数据
    self.pickerBusLineData = [self.pickerBusData allKeys];
    //    默认取出第一个线路所有数据
    NSString *selectedStation = [self.pickerBusLineData objectAtIndex:0];
    self.pickerBusStationData = [self.pickerBusData objectForKey:selectedStation];
}

#pragma mark UIPickerViewDataSorce
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
//    NSLog(@"哈哈哈5");
  return 2;
//    if(pickerViewSelect == 1){
//        return 1;
//    }else{ return 2;
//    }
    
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if(currentTransport ==1){
        if (component == 0){
            return [self.pickerSubwayLineData count];
        }else{
            return [self.pickerSubwayStationData count];
            
        }
    }else{
        if (component == 0){
            return [self.pickerBusLineData count];
        }else{
            return [self.pickerBusStationData count];
        }
        
    }
    
}


#pragma mark UIPickerViewDelegate
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(currentTransport ==1){
        if(component == 0){
            return [self.pickerSubwayLineData objectAtIndex:row];
        }else{
            return [self.pickerSubwayStationData objectAtIndex:row];
        }
    }else{
        if(component == 0){
            return [self.pickerBusLineData objectAtIndex:row];
        }else{
            return [self.pickerBusStationData objectAtIndex:row];
        }
    }
    
}
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    
    if(currentTransport ==1){
        if(component ==0){
            NSString *selectedLine = [self.pickerSubwayLineData objectAtIndex:row];
            NSArray *array = [self.pickerSubwayData objectForKey:selectedLine];
            self.pickerSubwayStationData = array;
            [pickerView reloadComponent:1];
        }
    }else{
        if(component ==0){
            NSString *selectedLine = [self.pickerBusLineData objectAtIndex:row];
            NSArray *array = [self.pickerBusData objectForKey:selectedLine];
            self.pickerBusStationData = array;
            [pickerView reloadComponent:1];

        }
    }
    
}



//初始化百度地图
-(void)mapDidLoad{
    //轨迹服务设置基础信息
    BTKServiceOption *sop = [[BTKServiceOption alloc] initWithAK:AK mcode:mcode serviceID:serviceID keepAlive:false];
    [[BTKAction sharedInstance] initInfo:sop];
    
    
    _mapView.delegate = self;
    //设置精度圈
    [self customLocationAccuracyCircle];
    
    //定位服务及poi搜索服务初始化
    _locService = [[BMKLocationService alloc] init];
    _poisearch = [[BMKPoiSearch alloc]init];
    
    //路线搜索初始化
    _routesearch = [[BMKRouteSearch alloc]init];
    
    _startAddrText.text = @"街道口";
    _endAddrText.text = @"光谷广场";
    busLine.text = @"轨道交通2号线";
    
    //公交搜索初始化
    currentIndex = -1;
    _buslinesearch = [[BMKBusLineSearch alloc]init];
    _busPoiArray = [[NSMutableArray alloc]init];
    
    //开始定位+跟随态
    NSLog(@"进入普通定位态");
    [_locService startUserLocationService];
    _mapView.showsUserLocation = NO;//先关闭显示的定位图层
    NSLog(@"进入罗盘态");
    _mapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading;
    
    //    地图设置
    _mapView.rotateEnabled = NO;
    _mapView.scrollEnabled = NO;
    _mapView.showsUserLocation = YES;
    
    //初始化轨迹点
    sportNodes = [[NSMutableArray alloc] init];
    
    //初始化地铁状态判断
    statusJudgement = [[StatusJudgement alloc] init];
    
    //   CLLocationDistance distance = BMKMetersBetweenMapPoints(BMKMapPoint a, BMKMapPoint b)
}
//自定义精度圈
- (void)customLocationAccuracyCircle {
    BMKLocationViewDisplayParam *param = [[BMKLocationViewDisplayParam alloc] init];
    param.isAccuracyCircleShow = NO;
    [_mapView updateLocationViewWithParam:param];
    [_mapView setZoomLevel:17];
}

-(void)removeAllStations{
    [busStations removeAllObjects];
    busStations = [[NSMutableArray alloc] init];
    [_busPoiArray removeAllObjects];
    NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    currentStationIndex = 0;
}

-(void)viewWillAppear:(BOOL)animated {
    [_mapView viewWillAppear];
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
    _locService.delegate = self;
    _buslinesearch.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
    _poisearch.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
    _routesearch.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
}

-(void)viewWillDisappear:(BOOL)animated {
    [_mapView viewWillDisappear];
    _mapView.delegate = nil; // 不用时，置nil
    _locService.delegate = nil;
    _buslinesearch.delegate = nil; // 不用时，置nil
    _poisearch.delegate = nil; // 不用时，置nil
    _routesearch.delegate = nil; // 不用时，置nil
    
}

#pragma mark - BMKMapViewDelegate
- (BMKAnnotationView *)mapView:(BMKMapView *)view viewForAnnotation:(id <BMKAnnotation>)annotation
{
    NSLog(@"进入Annotation");
    if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        return [(RouteAnnotation*)annotation getRouteAnnotationView:view];
    } else if ([annotation isKindOfClass:[BMKPointAnnotation class]]){
        BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        NSLog(@"开始画点");
        newAnnotationView.pinColor = BMKPinAnnotationColorPurple;
        newAnnotationView.animatesDrop = YES;// 设置该标注点动画显示
        return newAnnotationView;
    }
    return nil;
}
//根据overlay生成对应的View
- (BMKOverlayView*)mapView:(BMKMapView *)map viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor alloc] initWithRed:0 green:1 blue:1 alpha:1];
        polylineView.strokeColor = [[UIColor alloc] initWithRed:0 green:0 blue:1 alpha:0.7];
        polylineView.lineWidth = 3.0;
        return polylineView;
    }
    return nil;
}

#pragma mark - BMKRouteSearchDelegate
- (void)onGetTransitRouteResult:(BMKRouteSearch*)searcher result:(BMKTransitRouteResult*)result errorCode:(BMKSearchErrorCode)error
{
    //  计算行程以及需要时间
    BMKTransitRouteLine* routeLine = [result.routes objectAtIndex:0];
    durationMinute = [NSNumber numberWithInt:routeLine.duration.minutes];
    durationDistance = [NSNumber numberWithFloat:(float)routeLine.distance/1000];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.roundingMode = NSNumberFormatterRoundFloor;
    formatter.maximumFractionDigits = 2;
    NSLog(@"行程大概需要：%@分钟",durationMinute);
    NSLog(@"行程长度大约：%@公里",durationDistance);
    _travelTime.text =[NSString stringWithFormat:@"%@",durationMinute];
    _travelDistance.text = [formatter stringFromNumber:durationDistance];
    //  画出地铁&公交线路
    NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
    [_mapView removeAnnotations:array];
    array = [NSArray arrayWithArray:_mapView.overlays];
    [_mapView removeOverlays:array];
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKTransitRouteLine* plan = (BMKTransitRouteLine*)[result.routes objectAtIndex:0];
        // 计算路线方案中的路段数目
        NSInteger size = [plan.steps count];
        NSLog(@"路段数目%ld",(long)size);
        int planPointCounts = 0;
        for (int i = 0; i < size; i++) {
            BMKTransitStep* transitStep = [plan.steps objectAtIndex:i];
            
            if(i==0){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.starting.location;
                //                NSLog(@"起点:%@",plan.starting.title);
                item.title = @"起点";
                item.type = 0;
                [_mapView addAnnotation:item]; // 添加起点标注
            }
            if(i==size-1){
                RouteAnnotation* item = [[RouteAnnotation alloc]init];
                item.coordinate = plan.terminal.location;
                //                NSLog(@"终点:%@",plan.terminal.title);
                item.title = @"终点";
                item.type = 1;
                [_mapView addAnnotation:item]; // 添加起点标注
            }
            RouteAnnotation* item = [[RouteAnnotation alloc]init];
            item.coordinate = transitStep.entrace.location;
            item.title = transitStep.instruction;
            item.type = 3;
            [_mapView addAnnotation:item];
            
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
            NSLog(@"轨迹点数总累计%d",planPointCounts);
        }
        
        //轨迹点
        BMKMapPoint * temppoints = new BMKMapPoint[planPointCounts];
        int i = 0;
        for (int j = 0; j < size; j++) {
            BMKTransitStep* transitStep = [plan.steps objectAtIndex:j];
            NSLog(@"起点是%@",transitStep.entrace.title);
            NSLog(@"终点是%@",transitStep.exit.title);
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {
                temppoints[i].x = transitStep.points[k].x;
                temppoints[i].y = transitStep.points[k].y;
                i++;
            }
            
        }
        // 通过points构建BMKPolyline
        BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:temppoints count:planPointCounts];
        [_mapView addOverlay:polyLine]; // 添加路线overlay
        delete []temppoints;
        [self mapViewFitPolyLine:polyLine];
    }
}

#pragma mark implement BMKSearchDelegate
- (void)onGetPoiResult:(BMKPoiSearch *)searcher result:(BMKPoiResult*)result errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        BMKPoiInfo* poi = nil;
        BOOL findBusline = NO;
        for (NSInteger i = 0; i < result.poiInfoList.count; i++) {
            poi = [result.poiInfoList objectAtIndex:i];
            if (poi.epoitype == 2 || poi.epoitype == 4) {
                findBusline = YES;
                [_busPoiArray addObject:poi];
            }
        }
        //开始bueline详情搜索
        if(findBusline)
        {
            currentIndex = 0;
            NSString* strKey = ((BMKPoiInfo*) [_busPoiArray objectAtIndex:currentIndex]).uid;
            BMKBusLineSearchOption *buslineSearchOption = [[BMKBusLineSearchOption alloc]init];
            buslineSearchOption.city= @"武汉";
            buslineSearchOption.busLineUid= strKey;
            BOOL flag = [_buslinesearch busLineSearch:buslineSearchOption];
            if(flag)
            {
                NSLog(@"busline检索发送成功");
            }
            else
            {
                NSLog(@"busline检索发送失败");
            }
            
        }
    }
}

- (void)onGetBusDetailResult:(BMKBusLineSearch*)searcher result:(BMKBusLineResult*)busLineResult errorCode:(BMKSearchErrorCode)error
{
    //记录站点信息
    NSInteger size = 0;
    size = busLineResult.busStations.count;
    bool flag = false;
    
    for (NSInteger j = 0; j < size; j++) {
        BMKBusStation* station = [busLineResult.busStations objectAtIndex:j];
        if([station.title isEqualToString:_startAddrText.text]||[station.title isEqualToString:_endAddrText.text]){
            flag = !flag;
        }
        if(flag==true||[station.title isEqualToString:_endAddrText.text]||[station.title isEqualToString:_startAddrText.text]){
            float latitude = station.location.latitude;
            float longitude = station.location.longitude;
            NSDictionary *busStation = [NSDictionary dictionaryWithObjectsAndKeys:station.title,@"station",[NSNumber numberWithFloat:latitude],@"latitude",[NSNumber numberWithFloat:longitude],@"longitude",nil];
            [busStations addObject:busStation];
        }
        //  BMKBusStation* start = [busLineResult.busStations objectAtIndex:0];
        //  [_mapView setCenterCoordinate:start.location animated:YES];
    }
    
    //  如果线路和输入相反  则逆置数组
    if([[busStations objectAtIndex:0][@"station"] isEqualToString:_endAddrText.text]){
        busStations = (NSMutableArray*)[[busStations reverseObjectEnumerator] allObjects];
        for (NSDictionary *i in busStations) {
            NSLog(@"%@",i[@"station"]);
        }
    }else{
        for (NSDictionary *i in busStations) {
            NSLog(@"%@",i[@"station"]);
        }
    }
}

#pragma mark - Button
- (IBAction)areaChoose:(id)sender {
    JFCityViewController *cityViewController = [[JFCityViewController alloc] init];
    cityViewController.title = @"城市";
    [cityViewController choseCityBlock:^(NSString *cityName) {
        areaChoose.title = cityName;
    }];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:cityViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
    
}

- (IBAction)buslineSelect:(id)sender {
    pickerViewSelect = 0;
    [self pickerViewShow];
}

- (IBAction)startStationSelect:(id)sender {
    pickerViewSelect = 0;
    [self pickerViewShow];
}

- (IBAction)endStationSelect:(id)sender {
    pickerViewSelect = 1;
    [self pickerViewShow];
}
//新公交路线规划 - 支持跨城公交
- (IBAction)onClickNewBusSearch:(id)sender {
    [self pickerViewDisappear];
    if(informationViewStatus == 0){
        [self shotMapModel];
        informationViewStatus = 0;
        [self removeAllStations];
        BMKCitySearchOption *citySearchOption = [[BMKCitySearchOption alloc]init];
        citySearchOption.pageIndex = 0;
        citySearchOption.pageCapacity = 10;
        citySearchOption.city=@"武汉";
        citySearchOption.keyword = busLine.text; //@"轨道交通2号线";
        BOOL flag = [_poisearch poiSearchInCity:citySearchOption];
        if(flag)
        {
            NSLog(@"城市内检索发送成功");
        }
        else
        {
            NSLog(@"城市内检索发送失败");
        }
        
        //    画点
        BMKPlanNode* start = [[BMKPlanNode alloc]init];
        start.name = _startAddrText.text;
        BMKPlanNode* end = [[BMKPlanNode alloc]init];
        end.name = _endAddrText.text;
        
        BMKTransitRoutePlanOption *transitRouteSearchOption = [[BMKTransitRoutePlanOption alloc]init];
        transitRouteSearchOption.city= @"武汉市";
        transitRouteSearchOption.from = start;
        transitRouteSearchOption.to = end;
        flag = [_routesearch transitSearch:transitRouteSearchOption];
        if(flag)
        {
            NSLog(@"bus检索发送成功");
        }
        else
        {
            NSLog(@"bus检索发送失败");
        }
        starServiceButton.enabled = true;
    }else if(informationViewStatus == 1){
        [self shotMapModel];
    }
}

- (IBAction)stopService:(id)sender {
    if(currentTransport == 1){
        [self stopSubwayService];
    }else
    {
        [self stopBusService];
    }
}

- (IBAction)startService:(id)sender {
    
    if(currentTransport == 1){
        [self startSubwayService];
    }else{
        [self startBusService];
    }
}

- (IBAction)hideInformationButton:(id)sender {
    [UIView animateWithDuration:0.8 animations:^{
        infomationView.frame = CGRectMake(0,-32, 414,128);
        _mapView.frame = CGRectMake(0, 104, 414, 568);
    }];
}
//改变交通工具
- (IBAction)transportSelect:(id)sender {
   
    if(currentTransport == 1){
        [self stopSubwayService];
        [self longMapModel];
        [self pickerViewDisappear];
    }else{
        [self stopBusService];
        [self longMapModel];
        [self pickerViewDisappear];
        
    }
  
    if (transportSelector.isOn){
        [self removeAllStations];
        naviTitle.title = @"地铁";
        currentTransport = 1;
        [self pickerView];
        [self selectStartStation];
        [self selectEndStation];
        
    }else{
       
        [self removeAllStations];
        naviTitle.title = @"公交";
        currentTransport = 0;
        [self pickerView];
        [self selectStartStation];
        [self selectEndStation];
       
        
    }
    
}

- (IBAction)selectStation:(id)sender {
    
    if(pickerViewSelect == 0 ){
        [self selectStartStation];
        [self pickerViewDisappear];
    }else if (pickerViewSelect == 1){
        [self selectEndStation];
        [self pickerViewDisappear];
    }
    
    
}

-(void)selectStartStation{
    NSInteger row1 = [pickerView selectedRowInComponent:0];
    NSInteger row2 = [pickerView selectedRowInComponent:1];
    if(currentTransport ==1){
        
        NSString *selected1 = [self.pickerSubwayLineData objectAtIndex:row1];
        NSString *selected2 = [self.pickerSubwayStationData objectAtIndex:row2];
        NSLog(@"%@,%@",selected1,selected2);
        busLine.text = selected1;
        _startAddrText.text = selected2;
        _endAddrText.text = selected2;
    }else{
        NSString *selected1 = [self.pickerBusLineData objectAtIndex:row1];
        NSString *selected2 = [self.pickerBusStationData objectAtIndex:row2];
        NSLog(@"%@,%@",selected1,selected2);
        busLine.text = selected1;
        _startAddrText.text = selected2;
        _endAddrText.text = selected2;
    }
}

-(void)selectEndStation{
    NSInteger row1 = [pickerView selectedRowInComponent:0];
    NSInteger row2 = [pickerView selectedRowInComponent:1];
    if(currentTransport == 1){
        NSString *selected1 = [self.pickerSubwayLineData objectAtIndex:row1];
        NSString *selected2 = [self.pickerSubwayStationData objectAtIndex:row2];
        NSLog(@"%@",selected2);
        _endAddrText.text = selected2;
    }else{
        NSString *selected1 = [self.pickerBusLineData objectAtIndex:row1];
        NSString *selected2 = [self.pickerBusStationData objectAtIndex:row2];
        NSLog(@"%@",selected2);
        _endAddrText.text = selected2;
    }
    
}

-(void)pickerViewShow{
    pickerViewStatus = 1;
    searchButton.enabled = false;
    [UIView animateWithDuration:0.8 animations:^{
//        infomationView.frame = CGRectMake(0,104, 414,128);
        infomationView.frame = CGRectMake(0,-32, 414,128);
        pickerViewBackground.frame = CGRectMake(0,104,414,175);
        _mapView.frame = CGRectMake(0, 281, 414, 391);
    }];
    
}

-(void)pickerViewDisappear{
    pickerViewStatus = 0;
    searchButton.enabled = true;
    [UIView animateWithDuration:0.8 animations:^{
        //        infomationView.frame = CGRectMake(0,104, 414,128);
        infomationView.frame = CGRectMake(0,-32, 414,128);
        pickerViewBackground.frame = CGRectMake(0,-179,414,175);
        _mapView.frame = CGRectMake(0, 104, 414, 568);
    }];
}

-(void)startSubwayService{
    informationViewStatus = 1;
    searchButton.enabled = false;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.roundingMode = NSNumberFormatterRoundFloor;
    formatter.maximumFractionDigits = 2;
    _travelTime.text =[NSString stringWithFormat:@"%@",durationMinute];
    _travelDistance.text = [formatter stringFromNumber:durationDistance];
    //  开启鹰眼服务
    BTKStartServiceOption *op = [[BTKStartServiceOption alloc] initWithEntityName:entityName];
    [[BTKAction sharedInstance] startService:op delegate:self];
    
    //初始化实体
    NSDictionary *columnKey = @{@"city":@"wh"};
    BTKAddEntityRequest *request = [[BTKAddEntityRequest alloc] initWithEntityName:entityName entityDesc:@"实体A" columnKey:columnKey serviceID:serviceID tag:31];
    [[BTKEntityAction sharedInstance] addEntityWith:request delegate:self];
    
    //  开启收集服务
    [[BTKAction sharedInstance] startGather:self];
    //  初始化定时器
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(subwayStatusJudge) userInfo:nil repeats:YES];
    //      [timer fire];
    starServiceButton.enabled = false;
    stopServiceButton.enabled = true;
    stateText.hidden = false;
    busLine.enabled = false;
    _startAddrText.enabled = false;
    _endAddrText.enabled = false;
}

-(void)stopSubwayService{
    informationViewStatus = 0;
    searchButton.enabled = true;
    [self removeAllStations];
    [timer invalidate];
    [[BTKAction sharedInstance] stopService:self];
    [[BTKAction sharedInstance] stopGather:self];
    //   删除实体
    BTKDeleteEntityRequest *request = [[BTKDeleteEntityRequest alloc] initWithEntityName:entityName serviceID:serviceID tag:32];
    [[BTKEntityAction sharedInstance] deleteEntityWith:request delegate:self];
    [timer invalidate];
//    if(informationViewStatus == 1){
//        starServiceButton.enabled = true;
//    }else{
//        starServiceButton.enabled = false;
//    }
    starServiceButton.enabled = true;
    stopServiceButton.enabled = false;
    _travelTime.text = @"0";
    _travelDistance.text = @"0";
    currentStationText.text = @"当前站";
    nextStationText.text = @"下一站";
    stateText.hidden = true;
    busLine.enabled = true;
    _startAddrText.enabled = true;
    _endAddrText.enabled = true;

}

-(void)startBusService{
    informationViewStatus = 1;
    searchButton.enabled = false;
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(busStatusJudge) userInfo:nil repeats:YES];
    //      [timer fire];
    currentStationIndex = 0;
    starServiceButton.enabled = false;
    stopServiceButton.enabled = true;
    stateText.hidden = false;
    busLine.enabled = false;
    _startAddrText.enabled = false;
    _endAddrText.enabled = false;
}

-(void)stopBusService{
    informationViewStatus = 0;
    searchButton.enabled = true;
    [self removeAllStations];
    [timer invalidate];
//    if(informationViewStatus == 1){
//        starServiceButton.enabled = true;
//    }else{
//        starServiceButton.enabled = false;
//    }
    starServiceButton.enabled = true;
    stopServiceButton.enabled = false;
    _travelTime.text = @"0";
    _travelDistance.text = @"0";
    currentStationText.text = @"当前站";
    nextStationText.text = @"下一站";
    stateText.hidden = true;
    busLine.enabled = true;
    _startAddrText.enabled = true;
    _endAddrText.enabled = true;

}


-(void)shotMapModel{
    [UIView animateWithDuration:0.8 animations:^{
        infomationView.frame = CGRectMake(0,104, 414,128);
        _mapView.frame = CGRectMake(0, 234, 414, 438);
    }];
    
}

-(void)longMapModel{
    [UIView animateWithDuration:0.8 animations:^{
        infomationView.frame = CGRectMake(0,-32, 414,128);
        _mapView.frame = CGRectMake(0, 104, 414, 568);
    }];

}


#pragma mark - service轨迹服务 回调
-(void)onStartService:(BTKServiceErrorCode)error {
    NSLog(@"start service response: %lu", (unsigned long)error);
}

-(void)onStopService:(BTKServiceErrorCode)error {
    NSLog(@"stop service response: %lu", (unsigned long)error);
}

-(void)onStartGather:(BTKGatherErrorCode)error {
    NSLog(@"start gather response: %lu", (unsigned long)error);
}

-(void)onStopGather:(BTKGatherErrorCode)error {
    NSLog(@"stop gather response: %lu", (unsigned long)error);
}

#pragma mark - API track - 请求
- (void)queryTrackLatestPoint{
    BTKQueryTrackProcessOption *option = [[BTKQueryTrackProcessOption alloc] init];
    option.denoise = FALSE;
    option.mapMatch = TRUE;
    option.radiusThreshold = 55;
    option.transportMode = BTK_TRACK_PROCESS_OPTION_TRANSPORT_MODE_RIDING;
    BTKQueryTrackLatestPointRequest *request = [[BTKQueryTrackLatestPointRequest alloc] initWithEntityName:entityName processOption:option outputCootdType:BTK_COORDTYPE_BD09LL serviceID:serviceID tag:11];
    [[BTKTrackAction sharedInstance] queryTrackLatestPointWith:request delegate:self];
}

#pragma mark - API track - 回调
-(void)onQueryTrackLatestPoint:(NSData *)response {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil];
    
    
    NSDictionary *pointDict = [dict valueForKey:@"latest_point"];
    NSLog(@"track latestpoint response: %@", pointDict);
    
    currentNode = [[SportNode alloc] init];
    currentNode.coordinate = CLLocationCoordinate2DMake([pointDict[@"latitude"] doubleValue], [pointDict[@"longitude"] doubleValue]);
    //        sportNode.angle = [dict[@"angle"] doubleValue];
    //    sportNode.distance = [dict[@"distance"] doubleValue];
    currentNode.speed = [pointDict[@"speed"] doubleValue];
    [sportNodes addObject:currentNode];
    currentIndex = [sportNodes count]-1;
    
    //    sportNodeNum = sportNodes.count;
    //    sportAnnotation = [[BMKPointAnnotation alloc]init];
    //    sportAnnotation.title = @"current";
    //    sportAnnotation.coordinate = sportNode.coordinate;
    //    sportAnnotation.d
    //    [_mapView addAnnotation:sportAnnotation];
    
    //    _mapView.centerCoordinate = currentNode.coordinate;
    
}

-(void)onQueryTrackDistance:(NSData *)response {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"track distance response: %@", dict);
}

-(void)onQueryHistoryTrack:(NSData *)response {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"track history response: %@", dict);
    
}

#pragma mark - API entity - 回调
-(void)onAddEntity:(NSData *)response {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"add entity response: %@", dict);
}

-(void)onDeleteEntity:(NSData *)response {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"delete entity response: %@", dict);
}

#pragma mark - BMKMapViewDelegate
- (void)mapViewDidFinishLoading:(BMKMapView *)mapView {
    //[self start];
}

/**
 *在地图View将要启动定位时，会调用此函数
 *@param mapView 地图View
 */
- (void)willStartLocatingUser
{
    NSLog(@"start locate");
}

/**
 *用户方向更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    currentLocation = userLocation.location;
    [_mapView updateLocationData:userLocation];
    //    NSLog(@"heading is %@",userLocation.heading);
//    NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
}

/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    currentLocation = userLocation.location;
//    NSLog(@"%@",currentLocation);
    //    NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    [_mapView updateLocationData:userLocation];
}

/**
 *在地图View停止定位后，会调用此函数
 *@param mapView 地图View
 */
- (void)didStopLocatingUser
{
    NSLog(@"stop locate");
}

/**
 *定位失败后，会调用此函数
 *@param mapView 地图View
 *@param error 错误号，参考CLError.h中定义的错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"location error");
}


- (void)dealloc {
    if (_mapView) {
        _mapView = nil;
    }
}
#pragma mark - 私有
//根据polyline设置地图范围
- (void)mapViewFitPolyLine:(BMKPolyline *) polyLine {
    CGFloat ltX, ltY, rbX, rbY;
    if (polyLine.pointCount < 1) {
        return;
    }
    BMKMapPoint pt = polyLine.points[0];
    ltX = pt.x, ltY = pt.y;
    rbX = pt.x, rbY = pt.y;
    for (int i = 1; i < polyLine.pointCount; i++) {
        BMKMapPoint pt = polyLine.points[i];
        if (pt.x < ltX) {
            ltX = pt.x;
        }
        if (pt.x > rbX) {
            rbX = pt.x;
        }
        if (pt.y > ltY) {
            ltY = pt.y;
        }
        if (pt.y < rbY) {
            rbY = pt.y;
        }
    }
    BMKMapRect rect;
    rect.origin = BMKMapPointMake(ltX , ltY);
    rect.size = BMKMapSizeMake(rbX - ltX, rbY - ltY);
    //    画图后转到该区域
    //    [_mapView setVisibleMapRect:rect];
    //    _mapView.zoomLevel = _mapView.zoomLevel - 0.3;
}


#pragma mark --- JFLocationDelegate
//定位中...
- (void)locating {
    NSLog(@"定位中...");
}

//定位成功
- (void)currentLocation:(NSDictionary *)locationDictionary {
    NSString *city = [locationDictionary valueForKey:@"City"];
    if (![areaChoose.title isEqualToString:city]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"您定位到%@，确定切换城市吗？",city] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            areaChoose.title = city;
            [KCURRENTCITYINFODEFAULTS setObject:city forKey:@"locationCity"];
            [KCURRENTCITYINFODEFAULTS setObject:city forKey:@"currentCity"];
            [self.manager cityNumberWithCity:city cityNumber:^(NSString *cityNumber) {
                [KCURRENTCITYINFODEFAULTS setObject:cityNumber forKey:@"cityNumber"];
            }];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

/// 拒绝定位
- (void)refuseToUsePositioningSystem:(NSString *)message {
    NSLog(@"%@",message);
}

/// 定位失败
- (void)locateFailure:(NSString *)message {
    NSLog(@"%@",message);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
