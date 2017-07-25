//
//  SensorViewController.swift
//  Subway
//
//  Created by Mars on 2017/5/2.
//  Copyright © 2017年 Mingjun Ma. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import MapKit


class SensorViewController: UIViewController,CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let altimeter = CMAltimeter()
    var timer:Timer?
    var speed = 0.10//0.01
    var path = NSHomeDirectory()+"/Documents/out.csv"
    var file=FileHandle()
    var filemanager=FileManager()
    var x:Float = 0.0,y:Float = 0.0,z:Float = 0.0,max:Float = 0.0,cos:Float = 0.0,theta:Float = 0.0
    var myQueue:DispatchQueue?
    var show=""
    var presseData=0.00
    
    override func viewDidLoad(){
        super.viewDidLoad()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate=self
        locationManager.requestAlwaysAuthorization()
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates()
            print("开始加速度检测")
        }else {
            UIAlertView(title: "提示", message: "不支持加速度的设备", delegate: nil, cancelButtonTitle: "确定").show()
            print("不支持加速度的设备")
            return;
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = speed
            motionManager.startGyroUpdates()
            print("开始角速度检测")
        }else {
            UIAlertView(title: "提示", message: "不支持陀螺仪的设备", delegate: nil, cancelButtonTitle: "确定").show()
            print("不支持陀螺仪的设备")
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = speed
            motionManager.startMagnetometerUpdates()
            print("开始磁场检测")
        }else {
            UIAlertView(title: "提示", message: "不支持磁场的设备", delegate: nil, cancelButtonTitle: "确定").show()
            print("不支持磁场的设备")
        }
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = speed
            motionManager.startDeviceMotionUpdates()
            print("开始方向检测")
        }else {
            UIAlertView(title: "提示", message: "不支持方向的设备", delegate: nil, cancelButtonTitle: "确定").show()
            print("不支持方向的设备")
        }
        myQueue = DispatchQueue(label: "mars.judgeAcceleration", qos: .default, attributes: .concurrent)
        
//        altimeter.startRelativeAltitudeUpdates(to: myQueue, withHandler: <#CMAltitudeHandler#>)

        if CMAltimeter.isRelativeAltitudeAvailable(){
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                
                self.presseData = Double(data!.pressure)
                print("压力: \(self.presseData) kPa\n")
//                self.show+=NSString(format: "气压值\np=%.2f", data!.pressure) as String
//      
            })
        }else {
            UIAlertView(title: "提示", message: "不支持获取高度的设备", delegate: nil, cancelButtonTitle: "确定").show()
            print("不支持获取高度的设备")
            return
        }
        
        getsize()
        file = FileHandle(forUpdatingAtPath: path)!
        let de = UserDefaults(suiteName: "speed")
        let spd = de!.float(forKey: "speed")
        if spd != 0 {
            speedslider.value = spd
        }else {
            speedslider.value=0
        }
        
        speedslider.value = 1
        sliderchange(0 as AnyObject)
        
    }
    
    @IBOutlet var filesize: UILabel!
    @IBOutlet var wirteswitch: UISwitch!
    @IBOutlet var speedlabel: UILabel!
    @IBOutlet var speedslider: UISlider!
    @IBOutlet var sharebutton: UIButton!
    @IBAction func clear(_sender: AnyObject) {
        file.truncateFile(atOffset: 0)
        getsize()
    }
    @IBAction func clearfile(_ sender: AnyObject) {
        file.truncateFile(atOffset: 0)
        getsize()
    }
    
    
    @IBAction func sliderchange(_ sender: AnyObject) {
        let de = UserDefaults(suiteName: "speed")
        speed=(5+exp(Double(speedslider.value)))/1000.0
        de!.set(speedslider.value, forKey: "speed")
        setspeed()
    }
    @IBAction func share(_ sender: AnyObject) {
        let url = URL(string: "file://"+path)
        print(url)
        let controler = UIActivityViewController(activityItems: [url!], applicationActivities: nil)
        present(controler, animated: true, completion: nil)
        if controler.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
            let presentationController = controler.popoverPresentationController
            presentationController?.sourceView = sharebutton
        }
    }
    @IBOutlet weak var gpstext: UITextView!
    

    
    //  设置获取速度
    func setspeed(){
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.gyroUpdateInterval = speed
        motionManager.magnetometerUpdateInterval = speed
        motionManager.deviceMotionUpdateInterval = speed
        if timer != nil {
            timer?.invalidate()
        }
        timer=Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(SensorViewController.refresh), userInfo: nil, repeats: true)
        speedlabel.text="数据采集间隔:\(Int(speed*1000))毫秒,记录速度:\(Int(4.7/speed))KB/min"
        
    }
    
    @IBAction func logswitch(_ sender: AnyObject) {
        if wirteswitch.isOn {
            locationManager.startUpdatingLocation()
        }else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    @IBOutlet weak var showtext: UITextView!
    
    //显示数据
    func refresh(){
        show = ""
        
        //加速度传感器
        if let a = motionManager.accelerometerData
        {
            x=Float(a.acceleration.x)
            y=Float(a.acceleration.y)
            z=Float(a.acceleration.z)
            //            accx.value=Float(a.acceleration.x)
            //            accy.value=Float(a.acceleration.y)
            //            accz.value=Float(a.acceleration.z)
            cos=sqrt((x*x+z*z)/(x*x+y*y+z*z))
            theta=acos(cos)/3.1415926*180
            write("acc,\(x),\(y),\(z)")
            
            show+=NSString(format: "加速度\nx=%.2f\ny=%.2f\nz=%.2f\nθ=%.2f", x,y,z,theta) as String
            if theta<1 {
                show+="\t\t水平放置"
            }else if theta>85 {
                show+="\t\t垂直放置"
            }
        }
        
        //陀螺仪
        if let g = motionManager.gyroData{
            x = Float(g.rotationRate.x)
            y = Float(g.rotationRate.y)
            z = Float(g.rotationRate.z)
            max=abs(x)
            if abs(y)>max {max=abs(y)}
            if abs(z)>max {max=abs(z)}
            
            show+=NSString(format: "\n\n陀螺仪\nx=%.2f\ny=%.2f\nz=%.2f", x,y,z) as String
            if max>0.5 {
                show+="\t\t正在转动"
            }
            //write("gyro,\(x),\(y),\(z)")
            if max<5 {max=5}
            //            gyrox.maximumValue=max
            //            gyroy.maximumValue=max
            //            gyroz.maximumValue=max
            //            gyrox.minimumValue=0-max
            //            gyroy.minimumValue=0-max
            //            gyroz.minimumValue=0-max
            //            gyrox.value=x
            //            gyroy.value=y
            //            gyroz.value=z
            
        }
        
        //磁力传感器
        if let m = motionManager.magnetometerData{
            x = Float(m.magneticField.x)
            y = Float(m.magneticField.y)
            z = Float(m.magneticField.z)
            
            max=abs(x)
            if abs(y)>max {max=abs(y)}
            if abs(z)>max {max=abs(z)}
            if max<300 {max=300}
            //            magx.maximumValue=max
            //            magy.maximumValue=max
            //            magz.maximumValue=max
            //            magx.minimumValue=0-max
            //            magy.minimumValue=0-max
            //            magz.minimumValue=0-max
            //            magx.value=Float(x)
            //            magy.value=Float(y)
            //            magz.value=Float(z)
            show+=NSString(format: "\n\n磁场\nx=%.2f\ny=%.2f\nz=%.2f\n", x,y,z) as String
            //  write("mag,\(x),\(y),\(z)")
            if max>1000 {
                show+="检测到磁铁或磁贴"
            }
        }
        
        //欧拉角传感器
        if let d = motionManager.deviceMotion?.attitude{
            x = Float(d.roll)
            y = Float(d.pitch)
            z = Float(d.yaw)
            
            x=x/3.1415926*180
            y=y/3.1415926*180
            z=z/3.1415926*180
            
            max=abs(x)
            if abs(y)>max {max=abs(y)}
            if abs(z)>max {max=abs(z)}
            if max<90 {max=90}
            //            orix.maximumValue=max
            //            oriy.maximumValue=max
            //            oriz.maximumValue=max
            //            orix.minimumValue=0-max
            //            oriy.minimumValue=0-max
            //            oriz.minimumValue=0-max
            //
            //            orix.value = Float(x)
            //            oriy.value = Float(y)
            //            oriz.value = Float(z)
            
//            show+=NSString(format: "\n\n欧拉角\nrow=%.2f\npitch=%.2f\nyaw=%.2f", x,y,z) as String
            
            // write("ori,\(x),\(y),\(z)")
        }
        
        //气压传感器
        show+=NSString(format: "\n气压计\np=%.12f", self.presseData) as String
        write("pre,\(self.presseData)")

        
        
        showtext.text=show
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations[locations.count-1]
        if(location.horizontalAccuracy>0){
            let gps="GPS信息:\n经度:\(location.coordinate.latitude)\n纬度:\(location.coordinate.longitude)"
            gpstext.text=gps
            write("gps,\(location.coordinate.latitude),\(location.coordinate.longitude)")
            print(gps)
        }
    }
    
    func write(_ s:String){
        if wirteswitch.isOn {
            let s2="\(getTime()),\(s)\n"
            file.seekToEndOfFile()
            file.write(s2.data(using: String.Encoding.utf8, allowLossyConversion: true)!)
            getsize()
            print(s2)
        }
    }
    
    func getsize(){
        do{
            let fileSize = try (FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size] as! NSNumber).uint64Value
            if fileSize < 1048576{
                filesize.text=NSString(format: "%.3fKB", Double(fileSize)/1024.0) as String
            }else {
                filesize.text=NSString(format: "%.3fMB", Double(fileSize)/1048576.0) as String
            }
        }catch {
            try! "".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        }
    }
    
    func getTime() -> String{
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
