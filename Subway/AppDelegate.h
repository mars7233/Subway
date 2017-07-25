//
//  AppDelegate.h
//  Subway
//
//  Created by Mars on 2017/5/2.
//  Copyright © 2017年 Mingjun Ma. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,BMKGeneralDelegate>{
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

- (void)saveContext;


@end

