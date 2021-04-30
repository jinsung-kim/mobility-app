//
//  TimeSince.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 4/27/21.
//

import Foundation

/// This function gets the current time in milliseconds since 1970
/// It is used subtracted with another to get the time interval
func getCurrentMillis() -> Int {
    return Int(Date().timeIntervalSince1970 * 1000)
}
