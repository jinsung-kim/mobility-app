//
//  Point.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import Foundation

public struct Point: Codable { // Without 'Codable', it will not turn into a JSON
    var time: String
    var steps: Int32
    var currSteps: Int32
    var distance: Int32
    var currDistance: Int32
    var coordinates: [String: [Double]] // All lat, long values held in the same place
    var avgPace: Double
    var currPace: Double
    var currCad: Double
    
    // Used to add each point within the JSON
    init(_ time: String, _ steps: Int32, _ distance: Int32, _ avgPace: Double,
         _ currPace: Double, _ currCad: Double, _ coordinates: [String: [Double]],
         _ currSteps: Int32, _ currDistance: Int32) {
        self.time = time
        self.steps = steps
        self.currSteps = currSteps
        self.coordinates = coordinates
        self.currCad = currCad
        self.avgPace = avgPace
        self.currPace = currPace
        self.distance = distance
        self.currDistance = currDistance
    }
    
    func convertToDictionary() -> [String : Any] {
        let dic: [String: Any] = ["time": self.time, "steps": self.steps, "currSteps": self.currSteps,
                                  "distance": self.distance, "currDistance": self.currDistance,
                                  "coordinates": self.coordinates, "avgPace": self.avgPace,
                                  "currPace": self.currPace, "currCad": self.currCad]
        return dic
    }
}
