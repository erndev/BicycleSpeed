//
//  ScanViewController.swift
//  BicycleSpeed
//
//  Copyright (c) 2015, Ernesto García
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//


import UIKit

class ScanUnwindSegue: UIStoryboardSegue {
  
  var sensor:CadenceSensor?
}

class ScanViewController: UITableViewController {
  
  
  struct Constants {
    static let SensorCellID = "SensorCellID"
  }
  
  var sensors = [CadenceSensor]()
  override func viewDidLoad() {
    
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   
    guard let tableSelection = tableView.indexPathForSelectedRow, let unwindSegue = segue as? ScanUnwindSegue
      else {
      return
    }
    unwindSegue.sensor = sensors[tableSelection.row]
    
  }

  func addSensor( sensor:CadenceSensor ) {
  
      let indexPath = NSIndexPath(forRow: sensors.count, inSection: 0)
      sensors.append(sensor)
      tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }
}


extension ScanViewController {
  
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return sensors.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SensorCellID)!
    let sensor = sensors[indexPath.row].peripheral
    cell.textLabel?.text  = sensor.name ?? sensor.identifier.UUIDString
    return cell
  }
  
}
