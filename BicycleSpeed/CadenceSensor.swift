//
//  Sensor.swift
//  BicycleSpeed
//
//  Copyright (c) 2015, Ernesto García
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//

import Foundation
import CoreBluetooth

/*
// Bluetooth  "Cycling Speed and Cadence"
https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.cycling_speed_and_cadence.xml

Service Cycling Speed and Cadence. Characteristic [2A5B]  // Measurement
Service Cycling Speed and Cadence. Characteristic [2A5C]  // Supported Features
Service Cycling Speed and Cadence. Characteristic [2A5D]  // Sensor location
Service Cycling Speed and Cadence. Characteristic [2A55]  // Control Point

*/

public struct BTConstants {
  static let CadenceService         = "1816"
  static let CSCMeasurementUUID     = "2a5b"
  static let CSCFeatureUUID         = "2a5c"
  static let SensorLocationUUID     = "2a5d"
  static let ControlPointUUID       = "2a55"
  static let WheelFlagMask:UInt8    = 0b01
  static let CrankFlagMask:UInt8    = 0b10
  static let DefaultWheelSize:UInt32   = 2170  // In millimiters. 700x30 (by default my bike's wheels) :)
  static let TimeScale              = 1024.0
}

protocol CadenceSensorDelegate {
  
  func errorDiscoveringSensorInformation(_ error:NSError)
  func sensorReady()
  func sensorUpdatedValues( speedInMetersPerSecond speed:Double?, cadenceInRpm cadence:Double?, distanceInMeters distance:Double? )
}

class CadenceSensor: NSObject {
  
  let peripheral:CBPeripheral
  var sensorDelegate:CadenceSensorDelegate?
  var measurementCharasteristic:CBCharacteristic?
  var lastMeasurement:Measurement?
  let wheelCircunference:UInt32
  
  
  init(peripheral:CBPeripheral , wheel:UInt32=BTConstants.DefaultWheelSize) {
    self.peripheral = peripheral
    wheelCircunference = wheel
  }
  
  func start() {
    self.peripheral.discoverServices(nil)
    self.peripheral.delegate = self
  }
  
  
  func stop() {
    if let measurementCharasteristic = measurementCharasteristic {
      peripheral.setNotifyValue(false, for: measurementCharasteristic)
    }
    
  }
  
  func handleValueData( _ data:Data ) {
    
      let measurement = Measurement(data: data, wheelSize: wheelCircunference)
      print("\(measurement)")
    
      let values = measurement.valuesForPreviousMeasurement(lastMeasurement)
      lastMeasurement = measurement
      
      sensorDelegate?.sensorUpdatedValues(speedInMetersPerSecond: values?.speedInMetersPerSecond, cadenceInRpm: values?.cadenceinRPM, distanceInMeters: values?.distanceinMeters)
  }
}



extension CadenceSensor : CBPeripheralDelegate {
  
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    guard error == nil else {
      sensorDelegate?.errorDiscoveringSensorInformation(NSError(domain: CBErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("Error receiving measurements updates", comment:"")]))
      
      return
    }
    print("notification status changed for [\(characteristic.uuid)]...")
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    
    print("Updated [\(characteristic.uuid)]...")
    
    guard error == nil  , let data = characteristic.value  else {
      
      return
    }
    
    handleValueData(data)
    
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard error == nil  else {
      sensorDelegate?.errorDiscoveringSensorInformation(error! as NSError)
      return
    }
    // Find the cadence service
    guard let cadenceService =  peripheral.services?.filter({ (service) -> Bool in
      return service.uuid == CBUUID(string: BTConstants.CadenceService)
    }).first else {
      
      sensorDelegate?.errorDiscoveringSensorInformation(NSError(domain: CBErrorDomain, code: NSNotFound, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("Cadence service not found for this peripheral", comment:"")]))
      return
    }
    // Discover the cadence service characteristics
    peripheral.discoverCharacteristics(nil, for:cadenceService )
    print("Cadence service discovered")
    
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    
    guard let characteristics = service.characteristics else {
      sensorDelegate?.errorDiscoveringSensorInformation(NSError(domain: CBErrorDomain, code: NSNotFound, userInfo: [NSLocalizedDescriptionKey:NSLocalizedString("No characteristics found for the cadence service", comment:"")]))
      return
      
    }
    
    print("Received characteristics");
    
    // Enable notifications for the measurement characteristic
    for characteristic in characteristics {
      
      print("Service \(service.uuid). Characteristic [\(characteristic.uuid)]")
      
      if characteristic.uuid == CBUUID(string: BTConstants.CSCMeasurementUUID) {
        
        print("Found measurement characteristic. Subscribing...")
        peripheral.setNotifyValue(true, for: characteristic)
        measurementCharasteristic  = characteristic
        
      }
    }
    sensorDelegate?.sensorReady()
    
  }
  
}
