//
//  Measurement.swift
//  BicycleSpeed
//
//  Copyright (c) 2015, Ernesto García
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//

import Foundation
import CoreBluetooth

// CSC Measurement
// https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.csc_measurement.xml
//
//  Flags : 1 byte.  Bit 0: Wheel. Bit 1: Crank
//  Cumulative Wheel revolutions: 4 bytes uint32
//  Last wheel event time: 2 bytes. uint16 (1/1024s)
//  Cumulative Crank revolutions: 2 bytes uint16
//  Last cranck event time: 2 bytes. uint16 (1/1024s)


struct Measurement : CustomDebugStringConvertible {
  
  let hasWheel:Bool
  let hasCrank:Bool
  let cumulativeWheel:UInt32
  let lastWheelEventTime:NSTimeInterval
  let cumulativeCrank:UInt16
  let lastCrankEventTime:NSTimeInterval
  let wheelSize:UInt32
  
  
  init(data:NSData, wheelSize:UInt32) {
    
    self.wheelSize = wheelSize
    // Flags
    var flags:UInt8=0
    data.getBytes(&flags, range: NSRange(location: 0, length: 1))
    
    hasWheel = ((flags & BTConstants.WheelFlagMask) > 0)
    hasCrank = ((flags & BTConstants.CrankFlagMask) > 0)
    
    var wheel:UInt32=0
    var wheelTime:UInt16=0
    var crank:UInt16=0
    var crankTime:UInt16=0
    
    var currentOffset = 1
    var length = 0
    
    if ( hasWheel ) {
      
      length = sizeof(UInt32)
      data.getBytes(&wheel, range: NSRange(location: currentOffset, length: length))
      currentOffset += length
      
      length = sizeof(UInt16)
      data.getBytes(&wheelTime, range: NSRange(location: currentOffset, length: length))
      currentOffset += length
    }
    
    if ( hasCrank ) {
      
      length = sizeof(UInt16)
      data.getBytes(&crank, range: NSRange(location: currentOffset, length: length))
      currentOffset += length
      
      length = sizeof(UInt16)
      data.getBytes(&crankTime, range: NSRange(location: currentOffset, length: length))
      currentOffset += length
    }
    
    cumulativeWheel     = CFSwapInt32LittleToHost(wheel)
    lastWheelEventTime  = NSTimeInterval( Double(CFSwapInt16LittleToHost(wheelTime))/BTConstants.TimeScale)
    cumulativeCrank     = CFSwapInt16LittleToHost(crank)
    lastCrankEventTime  = NSTimeInterval( Double(CFSwapInt16LittleToHost(crankTime))/BTConstants.TimeScale)
    
  }
  
  func timeIntervalForCurrentSample( current:NSTimeInterval, previous:NSTimeInterval ) -> NSTimeInterval {
    var timeDiff:NSTimeInterval = 0
    if( current >= previous ) {
        timeDiff = current - previous
    }
    else {
      // passed the maximum value
      timeDiff =  ( NSTimeInterval((Double( UINT16_MAX) / BTConstants.TimeScale)) - previous) + current
    }
    return timeDiff
    
  }
  
  func valueDiffForCurrentSample<T:UnsignedIntegerType>( current:T, previous:T , max:T) -> T {
    
    var diff:T = 0
    if  ( current >= previous ) {
      diff = current - previous
    }
    else {
       diff = ( max - previous ) + current
    }
    return diff
  }
  
  
  func valuesForPreviousMeasurement( previousSample:Measurement? ) -> ( cadenceinRPM:Double?, distanceinMeters:Double?, speedInMetersPerSecond:Double?)? {
    
    
    var distance:Double?, cadence:Double?, speed:Double?
    guard let previousSample = previousSample else {
      return nil
    }
    if ( hasWheel && previousSample.hasWheel ) {
      let wheelTimeDiff = timeIntervalForCurrentSample(lastWheelEventTime, previous: previousSample.lastWheelEventTime)
      let valueDiff = valueDiffForCurrentSample(cumulativeWheel, previous: previousSample.cumulativeWheel, max: UInt32.max)
      
      distance = Double( valueDiff * wheelSize) / 1000.0 // distance in meters
      if  distance != nil  &&  wheelTimeDiff > 0 {
        speed = (wheelTimeDiff == 0 ) ? 0 : distance! / wheelTimeDiff // m/s
      }
    }
    
    if( hasCrank && previousSample.hasCrank ) {
      let crankDiffTime = timeIntervalForCurrentSample(lastCrankEventTime, previous: previousSample.lastCrankEventTime)
      let valueDiff = Double(valueDiffForCurrentSample(cumulativeCrank, previous: previousSample.cumulativeCrank, max: UInt16.max))
      
      cadence = (crankDiffTime == 0) ? 0 : Double(60.0 * valueDiff / crankDiffTime) // RPM
    }
    print( "Cadence: \(cadence) RPM. Distance: \(distance) meters. Speed: \(speed) Km/h" )
    return ( cadenceinRPM:cadence, distanceinMeters:distance, speedInMetersPerSecond:speed)
  }
  
  var debugDescription:String {
    get {
        return "Wheel Revs: \(cumulativeWheel). Last wheel event time: \(lastWheelEventTime). Crank Revs: \(cumulativeCrank). Last Crank event time: \(lastCrankEventTime)"
    }
  }
  
}