//
//  Gyro.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import Foundation

public struct Gyro: Codable { // Without 'Codable', it will not turn into a JSON
    var time: String
    var gyroData: [String: [Double]]
    var accelData: [String: [Double]]
    
    // Used to add each point within the JSON
    init(_ time: String, _ gyroData: [String: [Double]], _ accelData: [String: [Double]]) {
        self.time = time
        self.gyroData = gyroData
        self.accelData = accelData
    }
    
    func convertToDictionary2() -> [String : Any] {
        let dic: [String: Any] = ["time": self.time,
                                  "gyroData": self.gyroData,
                                  "accelData": self.accelData]
        return dic
    }
}
