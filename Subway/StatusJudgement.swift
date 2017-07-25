//
//  StatusJudgement.swift
//  Subway
//
//  Created by Mars on 2017/5/12.
//  Copyright © 2017年 Mingjun Ma. All rights reserved.

import Foundation
import CoreMotion

public class StatusJudgement:NSObject{
    
    let motionManager = CMMotionManager()
    let accelerTime:Float = 6
    let decelerTime:Float = 6
    var x:Float=0,y:Float=0,z:Float=0,cos:Float=0,theta:Float=0
    var acc:Float = 0
    var speed = 0.10//0.01
    var myQueue:DispatchQueue?
    
    //    init(acc:Float) {
    //        self.acc = sqrt(sqrt(abs(acc)))
    //    }
    
   public func getyAccelerValue() -> Float {
        motionManager.accelerometerUpdateInterval = speed
        motionManager.startAccelerometerUpdates()
//        print("开始加速度检测")
        if let a = motionManager.accelerometerData
        {
            x=Float(a.acceleration.x)
            y=Float(a.acceleration.y)
            z=Float(a.acceleration.z)
            cos=sqrt((x*x+z*z)/(x*x+y*y+z*z))
            theta=acos(cos)/3.1415926*180
            acc = sqrt(sqrt(abs(y)))
        }
        return acc
    }
    
    //判断是否达到关键点
    public func isLimitPoint(acc:Float) -> Bool {
        if(acc >= 0.6 || acc <= 0.4){
            return true
        }
        else{
            return false
        }
    }
    
    
    //判断状态，1为加速，2为减速，0为正常行驶
    func statusJudges() ->NSInteger{
        if(self.isLimitPoint(acc: getyAccelerValue())&&self.getyAccelerValue() < 0.4){
            var countTime = accelerTime/2
            var judge = 0
            var state = 0
            let queue = DispatchQueue(label: "mars.judgeAcceleration", qos: .default, attributes: .concurrent)
            let codeTimer = DispatchSource.makeTimerSource(queue:queue)
            codeTimer.scheduleRepeating(deadline: .now(), interval: .milliseconds(200))
            codeTimer.setEventHandler(handler: {
                countTime = countTime-0.2
                if countTime <= 0{
                    codeTimer.cancel()
                }
                if (self.getyAccelerValue()<=0.4){
                    judge = judge+1
                }
                if (judge>=8){
                    state = 1
                }else{
                    state = 0
                }
                
            })
            codeTimer.activate()
            sleep(3)
            if (state == 1){
                 print(getTime(),"正在加速")
                return 1
            }else{
                print(getyAccelerValue())
                print(getTime(),"达到加速值，但不在加速")
                return 0
            }
        }else if(self.isLimitPoint(acc: getyAccelerValue())&&getyAccelerValue() >= 0.6){
            var countTime = decelerTime/2
            var judge = 0
            var state = 0
            let queue = DispatchQueue(label: "mars.judgeDeceleration", qos: .default, attributes: .concurrent)
            let codeTimer = DispatchSource.makeTimerSource(queue:queue)
            codeTimer.scheduleRepeating(deadline: .now(), interval: .milliseconds(200))
            codeTimer.setEventHandler(handler: {
                countTime = countTime-0.2
                if countTime <= 0{
                    codeTimer.cancel()
                }
                if (self.getyAccelerValue()>=0.6){
                    judge = judge+1
                }
                if (judge>=8){
                    state = 1
                }else{
                    state = 0
                }
                
            })
            codeTimer.activate()
            sleep(3)
            if (state == 1){
                print(getTime(),"正在减速")
                return 2
            }else{
                print(getTime(),"达到减速值，但不在减速")
                return 0
            }
        }else{
            print(getTime(),"正常行驶")
            return 0
        }
    }
    
    
   public func getTime() -> String{
        let timespan = Date().timeIntervalSince1970//*1000
        //        return "\(Int64(timespan))"
        
        let timeInterval:TimeInterval = TimeInterval(timespan)
        let date = NSDate(timeIntervalSince1970: timeInterval)
        
        //格式话输出
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        return "\(dformatter.string(from: date as Date))"
        
    }
    
    
    
}
