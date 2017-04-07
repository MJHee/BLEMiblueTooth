//
//  ViewController.swift
//  BLEMiblueTooth
//
//  Created by MJHee on 2017/4/7.
//  Copyright © 2017年 MJBaby. All rights reserved.
//

import UIKit

import CoreBluetooth

let STEP = "FF06"
let BUTERY = "FF0C"
let SHAKE = "2A06"
let DEVICE = "FF01"

extension ViewController {
//MARK: -    CBCentralManagerDelegate
    //当前蓝牙主设备状态
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.title = "蓝牙已就绪"
            self.ConnectBtn.isEnabled = true
        }else {
            self.title = "蓝牙未准备好"
            self.ActionID.stopAnimating()
            switch central.state {
                case .unknown:
                    print(">>>CBCentralManagerStateUnknown")
                case .resetting:
                    print(">>>CBCentralManagerStateResetting")
                case .unsupported:
                    print(">>>CBCentralManagerStateUnsupported")
                case .unauthorized:
                    print(">>>CBCentralManagerStateUnauthorized")
                case .poweredOff:
                    print(">>>CBCentralManagerStatePoweredOff")
                    
                default: break
                
            }
        }
    }
    
    //扫描到设备会进入方法
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        central.connect(peripheral, options: nil)
        if (peripheral.name?.hasSuffix("MI"))! {
            thePerpher = peripheral
            central.stopScan()
            central.connect(peripheral, options: nil)
            self.title = "发现小米手环，开始连接..."
            self.ResultTextV.text = "发现手环：" + "\(peripheral.identifier)" + "\n名称：" + "\(peripheral.name)" + "\n"
        }
    }
    
//mark: - 设备扫描与连接的代理
    //连接到Peripherals-成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.title = "连接成功，扫描信息..."
        print("连接外设成功" + "\(peripheral.name)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("开始扫描外设服务" + "\(peripheral.name)")
    }
    
    //连接外设失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        print("连接到外设 失败！" + "\(error?.localizedDescription)")
        self.ActionID.stopAnimating()
        self.title = "连接失败"
        self.ConnectBtn.isEnabled = true
    }
    
    //扫描到服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            
            print("扫描外设服务出错：" + "\(error?.localizedDescription)")
            self.title = "扫描外设服务出错"
            self.ActionID.stopAnimating()
            self.ConnectBtn.isEnabled = true
            return
        }
        print("扫描外设服务：" + "\(peripheral.services)")
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("开始扫描外设服务的特征：" + "\(peripheral.name)")
    }
    
    //扫描到特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if (error != nil) {
            
            print("扫描外设的特征失败！" + "\(error?.localizedDescription)")
            self.title = "扫描外设的特征失败"
            self.ActionID.stopAnimating()
            self.ConnectBtn.isEnabled = true
            return
        }
        print("扫描外设的特征：" + "\(peripheral.name)" + "\(service.uuid)" + "\(service.characteristics)")
        for characteristics in service.characteristics! {
            peripheral.setNotifyValue(true, for: characteristics)
            //步数
            if characteristics.uuid.uuidString == STEP {
                peripheral.readValue(for: characteristics)
            }
            //电池电量
            else if characteristics.uuid.uuidString == BUTERY {
                peripheral.readValue(for: characteristics)
            }
            //震动
            else if characteristics.uuid.uuidString == SHAKE {
                theShakeCC = characteristics
            }
            //设备信息
            else if characteristics.uuid.uuidString == DEVICE {
                peripheral.readValue(for: characteristics)
            }
        }
    }
    
//mark: - 设备信息处理
    //扫描到具体的值
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if (error != nil) {
            
            print("扫描外设的特征失败！" + "\(error?.localizedDescription)")
            self.title = "扫描外设的特征失败"
            return
        }
        print("扫描外设的特征：" + "\(characteristic.uuid)" + "\(characteristic.value)")
        if characteristic.uuid.uuidString == STEP {
            
            let data = (characteristic.value! as NSData)
            let bytes = data.bytes.hashValue
            let steps = TCcbytesValueToInt(bytesValue: [UInt8(bytes)])
            print("步数：" + "\(steps)")
            self.ResultTextV.text = "\(self.ResultTextV.text)" + "步数：" + "\(steps)" + "\n"
        }
        //电池电量
        else if characteristic.uuid.uuidString == BUTERY {
            
            let data = (characteristic.value! as NSData)
            let bytes = data.bytes.hashValue
            let buterys = TCcbytesValueToInt(bytesValue: [UInt8(bytes)]) & 0xff
            print("电量：" + "\(buterys)")
            self.ResultTextV.text = "\(self.ResultTextV.text)" + "电量：" + "\(buterys)" + "\n"
        }
        //设备信息
        else if characteristic.uuid.uuidString == DEVICE {
            //这里解析infoByts得到设备信息
        }
        self.ActionID.stopAnimating()
        self.ConnectBtn.isEnabled = true
        self.title = "信息扫描完成"
    }
    
    //与外设断开连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("与外设备断开连接" + "\(peripheral.name)" + "\(error?.localizedDescription)")
        self.title = "连接已断开"
        self.ConnectBtn.isEnabled = true
    }
}


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var theManager : CBCentralManager! = nil
    var thePerpher : CBPeripheral! = nil
    var theShakeCC : CBCharacteristic! = nil

    @IBOutlet weak var ActionID: UIActivityIndicatorView!
    @IBOutlet weak var ConnectBtn: UIButton!
    @IBOutlet weak var ResultTextV: UITextView!
    
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        
        theManager = CBCentralManager.init(delegate: self, queue: nil)
        self.ConnectBtn.isEnabled = false
    }
    
    
    func TCcbytesValueToInt(bytesValue: [UInt8]) -> UInt32 {
        let array : [UInt8] = bytesValue
        var value : UInt32 = 0
        let data = NSData(bytes: array, length: 4)
        data.getBytes(&value, length: 4)
        value = UInt32(bigEndian: value)
        return value
    }
    
    
//连接
    @IBAction func connectAction(_ sender: UIButton) {
        if theManager.state == .poweredOn {
            print("主设备蓝牙状态正常，开始扫描外设...")
            self.title = "扫描小米手环"
            //nil表示扫描所有设备
            theManager.scanForPeripherals(withServices: nil, options: nil)
            self.ActionID.startAnimating()
            self.ConnectBtn.isEnabled = false
            self.ResultTextV.text = ""
        }
    }
//断开连接
    @IBAction func disConnectAction(_ sender: UIButton) {
        self.ActionID.stopAnimating()
        if (thePerpher != nil) {
            theManager.cancelPeripheralConnection(thePerpher)
            thePerpher = nil
            theShakeCC = nil
            self.title = "设备连接已断开"
        }
    }
//震动
    @IBAction func shakeBankAction(_ sender: UIButton) {
        if thePerpher != nil && theShakeCC != nil {
            var zd = [UInt8]()
            zd[1] = 2
            let theData : NSData = NSData.init(bytes: zd, length: 1)
            thePerpher.writeValue(theData as Data, for: theShakeCC, type: .withoutResponse)
        }
    }
//停止震动
    @IBAction func stopShakeAction(_ sender: UIButton) {
        if thePerpher != nil && theShakeCC != nil {
            var zd = [UInt8]()
            zd[1] = 0
            let theData : NSData = NSData.init(bytes: zd, length: 1)
            thePerpher.writeValue(theData as Data, for: theShakeCC, type: .withoutResponse)
        }
    }
}

