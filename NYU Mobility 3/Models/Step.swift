//
//  Step.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import Foundation

public struct Step: Codable { // Without 'Codable', it will not turn into a JSON
    var time: String
    var steps: Int32
    var currSteps: Int32
    var avgPace: Double
    var currPace: Double
    var currCad: Double
    
    // Used to add each point within the JSON
    init(_ time: String, _ steps: Int32, _ avgPace: Double,
         _ currPace: Double, _ currCad: Double, _ currSteps: Int32) {
        self.time = time
        self.steps = steps
        self.currSteps = currSteps
        self.currCad = currCad
        self.avgPace = avgPace
        self.currPace = currPace
    }
    
    // Called in actual tracking areas
    func convertToDictionary() -> [String : Any] {
        let dic: [String: Any] = ["time": self.time,
                                  "steps": self.steps,
                                  "currSteps": self.currSteps,
                                  "avgPace": self.avgPace,
                                  "currPace": self.currPace,
                                  "currCad": self.currCad]
        return dic
    }
}
