//
//  MainViewController.swift
//  BicycleSpeed
//
//  Copyright (c) 2015, Ernesto García
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController {

  
  struct Constants {
    
    static let ScanSegue = "ScanSegue"
    static let SensorUserDefaultsKey = "lastsensorused"
  }
  
  var bluetoothManager:BluetoothManager!
  var sensor:CadenceSensor?
  weak var scanViewController:ScanViewController?
  var infoViewController:InfoTableViewController?
  var accumulatedDistance:Double?
  
  lazy var distanceFormatter:LengthFormatter = {
    
    let formatter = LengthFormatter()
    formatter.numberFormatter.maximumFractionDigits = 1
    
    return formatter
  }()
  
  //@IBOutlet var labelBTStatus:UILabel!
  @IBOutlet var scanItem:UIBarButtonItem!
  @IBOutlet weak var idLabel: UILabel!
  
  
  override func viewDidLoad() {
      
      bluetoothManager = BluetoothManager()
      bluetoothManager.bluetoothDelegate = self
      scanItem.isEnabled = false
    
  }
  
  deinit {
    disconnectSensor()
  }
  
  @IBAction func unwindSegue( _ segue:UIStoryboardSegue ) {
      bluetoothManager.stopScan()
    guard let sensor = (segue as? ScanUnwindSegue)?.sensor else {
      return
    }
    print("Need to connect to sensor \(sensor.peripheral.identifier)")
    connectToSensor(sensor)
  
  }
  
  func disconnectSensor( ) {
    if sensor != nil  {
      bluetoothManager.disconnectSensor(sensor!)
      sensor = nil
    }
    accumulatedDistance = nil
  }
  
  func connectToSensor(_ sensor:CadenceSensor) {
    
    self.sensor  = sensor
    bluetoothManager.connectToSensor(sensor)
    // Save the sensor ID
    UserDefaults.standard.set(sensor.peripheral.identifier.uuidString, forKey: Constants.SensorUserDefaultsKey)
    UserDefaults.standard.synchronize()
    
  }
  // TODO: REconnect. Try this every X seconds
  func checkPreviousSensor() {
    
    guard let sensorID = UserDefaults.standard.object(forKey: Constants.SensorUserDefaultsKey)  as? String else {
      return
    }
    guard let sensor = bluetoothManager.retrieveSensorWithIdentifier(sensorID) else {
      return
    }
    self.sensor = sensor
    connectToSensor(sensor)
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let infoVC = segue.destination as? InfoTableViewController {
        infoViewController = infoVC
    }
    if segue.identifier == Constants.ScanSegue {
      
        // Scan segue
      bluetoothManager.startScan()
      scanViewController  = (segue.destination as? UINavigationController)?.viewControllers.first as? ScanViewController
    }
    
  }
  
}

extension MainViewController : CadenceSensorDelegate {
  
  func errorDiscoveringSensorInformation(_ error: NSError) {
      print("An error ocurred disconvering the sensor services/characteristics: \(error)")
  }
  
  func sensorReady() {
    print("Sensor ready to go...")
    accumulatedDistance = 0.0
  }
  
  func updateSensorInfo() {
    let name = sensor?.peripheral.name ?? ""
    let uuid = sensor?.peripheral.identifier.uuidString ?? ""
    
    OperationQueue.main.addOperation { () -> Void in
      self.infoViewController?.showDeviceName(name , uuid:uuid )
    }
  }
  
  
  func sensorUpdatedValues( speedInMetersPerSecond speed:Double?, cadenceInRpm cadence:Double?, distanceInMeters distance:Double? ) {
    
    accumulatedDistance? += distance ?? 0
    let distanceText = (accumulatedDistance != nil && accumulatedDistance! >= 1.0) ? distanceFormatter.string(fromMeters: accumulatedDistance!) : "N/A"
    let speedText = (speed != nil) ? distanceFormatter.string(fromValue: speed!*3.6, unit: .kilometer) + NSLocalizedString("/h", comment:"(km) Per hour") : "N/A"
    let cadenceText = (cadence != nil) ? String(format: "%.2f %@",  cadence!, NSLocalizedString("RPM", comment:"Revs per minute") ) : "N/A"
    
    OperationQueue.main.addOperation { () -> Void in
      
      self.infoViewController?.showMeasurementWithSpeed(speedText , cadence: cadenceText, distance: distanceText )
    }
  }

  
}

extension MainViewController : BluetoothManagerDelegate {
  
  func stateChanged(_ state: CBCentralManagerState) {
    print("State Changed: \(state)")
    var enabled = false
    var title = ""
    switch state {
    case .poweredOn:
        title = "Bluetooth ON"
        enabled = true
        // When the bluetooth changes to ON, try to reconnect to the previous sensor
        checkPreviousSensor()

    case .resetting:
        title = "Reseeting"
    case .poweredOff:
      title = "Bluetooth Off"
    case .unauthorized:
      title = "Bluetooth not authorized"
    case .unknown:
      title = "Unknown"
    case .unsupported:
      title = "Bluetooth not supported"
    }
    infoViewController?.showBluetoothStatusText( title )
    scanItem.isEnabled = enabled
  }
  

  
  func sensorConnection( _ sensor:CadenceSensor, error:NSError?) {
      print("")
    guard error == nil else {
      self.sensor = nil
      print("Error connecting to sensor: \(sensor.peripheral.identifier)")
      updateSensorInfo()
      accumulatedDistance = nil
      return
    }
    self.sensor = sensor
    self.sensor?.sensorDelegate = self
    print("Sensor connected. \(String(describing: sensor.peripheral.name)). [\(sensor.peripheral.identifier)]")
    updateSensorInfo()
    
    sensor.start()
  }
  
  func sensorDisconnected( _ sensor:CadenceSensor, error:NSError?) {
    print("Sensor disconnected")
    self.sensor = nil
  }
  
  func sensorDiscovered( _ sensor:CadenceSensor ) {
      scanViewController?.addSensor(sensor)
  }
  


}
