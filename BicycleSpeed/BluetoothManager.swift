//
//  BluetoothManager.swift
//  BicycleSpeed
//
//  Copyright (c) 2015, Ernesto García
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//

import Foundation
import CoreBluetooth



protocol BluetoothManagerDelegate {
  
  func stateChanged(state:CBCentralManagerState)
  func sensorDiscovered( sensor:CadenceSensor )
  func sensorConnection( sensor:CadenceSensor, error:NSError?)
  func sensorDisconnected( sensor:CadenceSensor, error:NSError?)
}



class BluetoothManager:NSObject {
  
  

  
  let bluetoothCentral:CBCentralManager
  var bluetoothDelegate:BluetoothManagerDelegate?
  let servicesToScan = [CBUUID(string: BTConstants.CadenceService)]
  
  override init()
  {
    bluetoothCentral = CBCentralManager()
    super.init()
    bluetoothCentral.delegate = self
  }
  
  deinit {
      stopScan()
  }
  
  func startScan() {
    
      bluetoothCentral.scanForPeripheralsWithServices(servicesToScan, options: nil )
  }
  
  func stopScan() {
    if bluetoothCentral.isScanning {
      bluetoothCentral.stopScan()
    }
  }
  
  func connectToSensor(sensor:CadenceSensor) {
      // just in case, disconnect pending connections first
      disconnectSensor(sensor)
      bluetoothCentral.connectPeripheral(sensor.peripheral, options: nil)
  }
  
  func disconnectSensor(sensor:CadenceSensor) {
      bluetoothCentral.cancelPeripheralConnection(sensor.peripheral)
  }
  
  func retrieveSensorWithIdentifier( identifier:String ) -> CadenceSensor? {
    guard let uuid  = NSUUID(UUIDString: identifier) else  {
      return nil
    }
    guard let peripheral = bluetoothCentral.retrievePeripheralsWithIdentifiers([uuid]).first else {
      return nil
    }
    return CadenceSensor(peripheral: peripheral)
  }
  
}

extension BluetoothManager:CBCentralManagerDelegate {
  
  func centralManagerDidUpdateState(central: CBCentralManager) {
    bluetoothDelegate?.stateChanged(central.state)
  }
  
  
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
      print("Peripeherals")
    let sensor = CadenceSensor(peripheral: peripheral)
    bluetoothDelegate?.sensorDiscovered(sensor)
  }
  
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
      bluetoothDelegate?.sensorConnection(CadenceSensor(peripheral: peripheral), error: nil)
  }
  
  func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    bluetoothDelegate?.sensorConnection(CadenceSensor(peripheral: peripheral), error: error)

  }
  
  
}