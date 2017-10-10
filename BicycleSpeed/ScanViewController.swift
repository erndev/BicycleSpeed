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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   
    guard let tableSelection = tableView.indexPathForSelectedRow, let unwindSegue = segue as? ScanUnwindSegue
      else {
      return
    }
    unwindSegue.sensor = sensors[tableSelection.row]
    
  }

  func addSensor( _ sensor:CadenceSensor ) {
  
      let indexPath = IndexPath(row: sensors.count, section: 0)
      sensors.append(sensor)
      tableView.insertRows(at: [indexPath], with: .automatic)
  }
}


extension ScanViewController {
  
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return sensors.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SensorCellID)!
    let sensor = sensors[indexPath.row].peripheral
    cell.textLabel?.text  = sensor.name ?? sensor.identifier.uuidString
    return cell
  }
  
}
