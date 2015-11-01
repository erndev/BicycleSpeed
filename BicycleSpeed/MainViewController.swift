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
  
  lazy var distanceFormatter:NSLengthFormatter = {
    
    let formatter = NSLengthFormatter()
    formatter.numberFormatter.maximumFractionDigits = 1
    
    return formatter
  }()
  
  //@IBOutlet var labelBTStatus:UILabel!
  @IBOutlet var scanItem:UIBarButtonItem!
  @IBOutlet weak var idLabel: UILabel!
  
  
  override func viewDidLoad() {
      
      bluetoothManager = BluetoothManager()
      bluetoothManager.bluetoothDelegate = self
      scanItem.enabled = false
    
  }
  
  deinit {
    disconnectSensor()
  }
  
  @IBAction func unwindSegue( segue:UIStoryboardSegue ) {
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
  
  func connectToSensor(sensor:CadenceSensor) {
    
    self.sensor  = sensor
    bluetoothManager.connectToSensor(sensor)
    // Save the sensor ID
    NSUserDefaults.standardUserDefaults().setObject(sensor.peripheral.identifier.UUIDString, forKey: Constants.SensorUserDefaultsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
    
  }
  // TODO: REconnect. Try this every X seconds
  func checkPreviousSensor() {
    
    guard let sensorID = NSUserDefaults.standardUserDefaults().objectForKey(Constants.SensorUserDefaultsKey)  as? String else {
      return
    }
    guard let sensor = bluetoothManager.retrieveSensorWithIdentifier(sensorID) else {
      return
    }
    self.sensor = sensor
    connectToSensor(sensor)
    
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let infoVC = segue.destinationViewController as? InfoTableViewController {
        infoViewController = infoVC
    }
    if segue.identifier == Constants.ScanSegue {
      
        // Scan segue
      bluetoothManager.startScan()
      scanViewController  = (segue.destinationViewController as? UINavigationController)?.viewControllers.first as? ScanViewController
    }
    
  }
  
}

extension MainViewController : CadenceSensorDelegate {
  
  func errorDiscoveringSensorInformation(error: NSError) {
      print("An error ocurred disconvering the sensor services/characteristics: \(error)")
  }
  
  func sensorReady() {
    print("Sensor ready to go...")
    accumulatedDistance = 0.0
  }
  
  func updateSensorInfo() {
    let name = sensor?.peripheral.name ?? ""
    let uuid = sensor?.peripheral.identifier.UUIDString ?? ""
    
    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
      self.infoViewController?.showDeviceName(name , uuid:uuid )
    }
  }
  
  
  func sensorUpdatedValues( speedInMetersPerSecond speed:Double?, cadenceInRpm cadence:Double?, distanceInMeters distance:Double? ) {
    
    accumulatedDistance? += distance ?? 0
    let distanceText = (accumulatedDistance != nil && accumulatedDistance! >= 1.0) ? distanceFormatter.stringFromMeters(accumulatedDistance!) : "N/A"
    let speedText = (speed != nil) ? distanceFormatter.stringFromValue(speed!*3.6, unit: .Kilometer) + NSLocalizedString("/h", comment:"(km) Per hour") : "N/A"
    let cadenceText = (cadence != nil) ? String(format: "%.2f %@",  cadence!, NSLocalizedString("RPM", comment:"Revs per minute") ) : "N/A"
    
    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
      
      self.infoViewController?.showMeasurementWithSpeed(speedText , cadence: cadenceText, distance: distanceText )
    }
  }

  
}

extension MainViewController : BluetoothManagerDelegate {
  
  func stateChanged(state: CBCentralManagerState) {
    print("State Changed: \(state)")
    var enabled = false
    var title = ""
    switch state {
    case .PoweredOn:
        title = "Bluetooth ON"
        enabled = true
        // When the bluetooth changes to ON, try to reconnect to the previous sensor
        checkPreviousSensor()

    case .Resetting:
        title = "Reseeting"
    case .PoweredOff:
      title = "Bluetooth Off"
    case .Unauthorized:
      title = "Bluetooth not authorized"
    case .Unknown:
      title = "Unknown"
    case .Unsupported:
      title = "Bluetooth not supported"
    }
    infoViewController?.showBluetoothStatusText( title )
    scanItem.enabled = enabled
  }
  

  
  func sensorConnection( sensor:CadenceSensor, error:NSError?) {
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
    print("Sensor connected. \(sensor.peripheral.name). [\(sensor.peripheral.identifier)]")
    updateSensorInfo()
    
    sensor.start()
  }
  
  func sensorDisconnected( sensor:CadenceSensor, error:NSError?) {
    print("Sensor disconnected")
    self.sensor = nil
  }
  
  func sensorDiscovered( sensor:CadenceSensor ) {
      scanViewController?.addSensor(sensor)
  }
  


}
