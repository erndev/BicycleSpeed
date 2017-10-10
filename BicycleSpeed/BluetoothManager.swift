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
  
  func stateChanged(_ state:CBCentralManagerState)
  func sensorDiscovered( _ sensor:CadenceSensor )
  func sensorConnection( _ sensor:CadenceSensor, error:NSError?)
  func sensorDisconnected( _ sensor:CadenceSensor, error:NSError?)
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
    
      bluetoothCentral.scanForPeripherals(withServices: servicesToScan, options: nil )
  }
  
  func stopScan() {
    if bluetoothCentral.isScanning {
      bluetoothCentral.stopScan()
    }
  }
  
  func connectToSensor(_ sensor:CadenceSensor) {
      // just in case, disconnect pending connections first
      disconnectSensor(sensor)
      bluetoothCentral.connect(sensor.peripheral, options: nil)
  }
  
  func disconnectSensor(_ sensor:CadenceSensor) {
      bluetoothCentral.cancelPeripheralConnection(sensor.peripheral)
  }
  
  func retrieveSensorWithIdentifier( _ identifier:String ) -> CadenceSensor? {
    guard let uuid  = UUID(uuidString: identifier) else  {
      return nil
    }
    guard let peripheral = bluetoothCentral.retrievePeripherals(withIdentifiers: [uuid]).first else {
      return nil
    }
    return CadenceSensor(peripheral: peripheral)
  }
  
}

extension BluetoothManager:CBCentralManagerDelegate {
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    var state: CBCentralManagerState { get { return CBCentralManagerState(rawValue: central.state.rawValue)! }}
    bluetoothDelegate?.stateChanged(state)
  }
  
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
      print("Peripeherals")
    let sensor = CadenceSensor(peripheral: peripheral)
    bluetoothDelegate?.sensorDiscovered(sensor)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
      bluetoothDelegate?.sensorConnection(CadenceSensor(peripheral: peripheral), error: nil)
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    bluetoothDelegate?.sensorConnection(CadenceSensor(peripheral: peripheral), error: error as NSError?)
  }

}
