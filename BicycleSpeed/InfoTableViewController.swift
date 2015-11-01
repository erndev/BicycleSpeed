//
//  InfoTableViewController.swift
//  BicycleSpeed
//
//  Copyright (c) 2015, Ernesto García
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//

import UIKit

class InfoTableViewController: UITableViewController {

  private struct Constants {
    
    static let BluetoothStatusSection=0
    static let DeviceSectionSection=1
    static let MeasurementsSection=2
    
    static let BluetoothStatusRow = 0
    static let DeviceNameRow = 0
    static let DeviceUUIDRow = 1
    static let SpeedRow = 0
    static let CadenceRow = 1
    static let DistanceRow = 2
    
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  func showBluetoothStatusText( text:String ) {
    showDetailText(text, atSection: Constants.BluetoothStatusSection, row:Constants.BluetoothStatusRow)
  }
  
  func showDeviceName( name:String? , uuid:String? ) {
    showDetailText(name ?? "", atSection: Constants.DeviceSectionSection, row:Constants.DeviceNameRow)
    showDetailText(uuid ?? "", atSection: Constants.DeviceSectionSection, row:Constants.DeviceUUIDRow)

  }

  
  func showMeasurementWithSpeed( speed:String, cadence:String, distance:String  ) {
    
    showDetailText(speed, atSection: Constants.MeasurementsSection, row:Constants.SpeedRow)
    showDetailText(cadence, atSection: Constants.MeasurementsSection, row:Constants.CadenceRow)
    showDetailText(distance, atSection: Constants.MeasurementsSection, row:Constants.DistanceRow)

  }
  

  func showDetailText( text:String , atSection section:Int, row:Int) {
    if let cell  = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section )) {
        cell.detailTextLabel?.text = text
    }
  }

}
