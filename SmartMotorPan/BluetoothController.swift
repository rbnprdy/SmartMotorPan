//
//  BluetoothController.swift
//  SmartMotorPan
//
//  Created by Ruben Purdy on 1/1/20.
//  Copyright © 2020 rbnprdy. All rights reserved.
//

import CoreBluetooth

let rs232ServiceCBUUID = CBUUID(string: "0x175F8F23-A570-49BD-9627-815A6A27DE2A")
let rs232ServiceCBUUID2 = CBUUID(string: "0xB2E7D564-C077-404E-9D29-B547F4512DCE")

let manufacturerNameStringCharacteristicCBUUID = CBUUID(string: "0x2A29")
let firmwareRevisionStringCharacteristicCBUUID = CBUUID(string: "0x2A26")
let batteryLevelCharacteristicCBUUID = CBUUID(string: "0x2A19")
let readCharacteristicCBUUID = CBUUID(string: "0xCACC07FF-FFFF-4C48-8FAE-A9EF71B75E26")
let writeUUID = CBUUID(string: "0x1CCE1EA8-BD34-4813-A00A-C76E028FADCB") // actually writes
let write2UUID = CBUUID(string: "0x20B9794F-DA1A-4D14-8014-A0FB9CEFB2F7") // throws error
let write3UUID = CBUUID(string: "0x48CBE15E-642D-4555-AC66-576209C50C1E") // starts up smart motor thing
let write4UUID = CBUUID(string: "0xDB96492D-CF53-4A43-B896-14CBBF3BF4F3") // no error but doesn't show up on terminal


class BluetoothController: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
    
    static let Singleton = BluetoothController()
    
    var loadingBluetooth = true
    
    var centralManager: CBCentralManager! = nil
    var rs232Peripheral: CBPeripheral!
    var writeCharacteristic: CBCharacteristic!
    
    // commands to run at startup
    var commands: [String] = []
    var currCommand = 0
    
    // ["SADDR0", "EIGN(2)", "EIGN(3)", "ZS", "SADDR0", "KP=220", "KD=200", "KI=110", "KL=1100", "F", "A=100", "V=100000", "MP", "P=0", "G"]
    
    func startCentralManager() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        print("Central Manager State: \(self.centralManager.state)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.centralManagerDidUpdateState(self.centralManager)
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("unkown")
        case .resetting:
            print("reset")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauth")
        case .poweredOff:
            print("poff")
        case .poweredOn:
            print("Bluetooth Powered On")
            centralManager.scanForPeripherals(withServices: [rs232ServiceCBUUID, rs232ServiceCBUUID2])
        @unknown default:
            print("default")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        rs232Peripheral = peripheral
        rs232Peripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(rs232Peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        rs232Peripheral.discoverServices(nil)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard let services = peripheral.services else { return }
            
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
                if characteristic.properties.contains(.read) {
    //                print("\(characteristic.uuid): properties contains .read")
                    peripheral.readValue(for: characteristic)
                }
                if characteristic.properties.contains(.notify) {
    //                print("\(characteristic.uuid): properties contains .notify")
                    rs232Peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.properties.contains(.write) {
    //                print("\(characteristic.uuid): properties contains .write")
                    if characteristic.uuid == writeUUID {
                        writeCharacteristic = characteristic
                        loadingBluetooth = false
                    }
                    
                }
            }
        }
        
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            switch characteristic.uuid {
            case manufacturerNameStringCharacteristicCBUUID:
                print("Manufacturer: \(manufacturerName(from: characteristic))")
            case firmwareRevisionStringCharacteristicCBUUID:
                print("Firmware Revision: \(firmwareRevision(from: characteristic))\n\n")
            case batteryLevelCharacteristicCBUUID:
                print("\nBattery Level: \(batteryLevel(from: characteristic))%")
            case readCharacteristicCBUUID:
                getBytes(from: characteristic, str: "readCharacteristic")
            case write2UUID:
                getBytes(from: characteristic, str: "write2")
            case write3UUID:
                getBytes(from: characteristic, str: "write3")
            default:
                print("Unhandled Characteristic UUID: \(characteristic.uuid)")
            }
        }
        
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
            if let e = error {
                print("error: \(e)")
            }
        }
        
    private func getBytes(from characteristic: CBCharacteristic, str: String) {
        guard let characteristicData = characteristic.value else {
            print("error")
            return
        }
        print("received from \(str): ", terminator: "")
        for byte in characteristicData {
            print("\(byte)", terminator: "")
        }
        print()
    }
    
    private func manufacturerName(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
            let name = String(data: characteristicData, encoding: .utf8) else { return "Error" }
        return name
    }
    
    public func startup(KP: Int, KD: Int, KI: Int, KL: Int, Acceleration: Int, Velocity: Int) {
        commands = ["SADDR0", "EIGN(2)", "EIGN(3)", "ZS", "SADDR0", "UAO", "UBO", "UA=1", "UB=0", "KP=\(KP)", "KD=\(KD)", "KI=\(KI)", "KL=\(KL)", "F", "A=\(Acceleration)", "V=\(Velocity)", "MP", "P=0", "G"]
        for command in commands {
            writeDataCommand(to: writeCharacteristic, command: command)
        }
    }
    
    public func move(distance: Int, sleepSwitch: Int, sleepMove: Int) {
        writeDataCommand(to: writeCharacteristic, command: "UA=0")
        writeDataCommand(to: writeCharacteristic, command: "UB=1")
        usleep(useconds_t(sleepSwitch))
        writeDataCommand(to: writeCharacteristic, command: "UA=1")
        writeDataCommand(to: writeCharacteristic, command: "UB=0")
        usleep(useconds_t(sleepMove))
        writeDataCommand(to: writeCharacteristic, command: "O=0")
        writeDataCommand(to: writeCharacteristic, command: "P=\(distance)")
        writeDataCommand(to: writeCharacteristic, command: "G")
        
    }
    
    private func firmwareRevision(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
            let name = String(data: characteristicData, encoding: .utf8) else { return "Error" }
        return name
    }
    
    private func batteryLevel(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
            let byte = characteristicData.first else { return "Error" }
        return "\(byte)"
    }
    
    private func writeDataCommand(to characteristic: CBCharacteristic, command: String) {
        guard var data = "\(command)".data(using: .utf8) else { return }
        let end: [UInt8] = [0x20, 0x0D]
        data.append(contentsOf: end)
        print("sending command \(command)")
        rs232Peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
}
