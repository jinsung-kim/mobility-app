//
//  Double+Truncate.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 4/29/21.
//

import Foundation

/// Used to truncate Doubles to a certain number of significant figures
/// Mainly for display features -> not for accuracy
extension Double {
    func truncate(places : Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * self) / pow(10.0, Double(places)))
    }
}
