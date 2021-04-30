//
//  TimeSince.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 4/27/21.
//

import Foundation

func getCurrentMillis() -> Int {
    return Int(Date().timeIntervalSince1970 * 1000)
}
