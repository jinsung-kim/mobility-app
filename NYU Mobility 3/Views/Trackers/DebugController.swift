//
//  DebugController.swift
//  NYU Mobility 3
//
//  A standard tracker like the no video controller that does real time
//  detection of possible veering by showing a graph
//
//  Created by Jin Kim on 3/29/21.
//

import UIKit
import CoreLocation
import CoreMotion

class DebugController: UIViewController, CLLocationManagerDelegate {
    
    var state: Int = 0 // Treat as flag for state (0 - not tracking, 1 - tracking)
    
    private let locationManager: CLLocationManager = CLLocationManager()
    private let pedometer: CMPedometer = CMPedometer()
    
    // Default values are negative so we know how to update the values
    var startTheta: Double = -1.0
    var endTheta: Double = -1.0
    
    var distance: Int = 0
    
    // Labels for debugging process
    @IBOutlet weak var sessionStatusLabel: UILabel!
    @IBOutlet weak var veeringLabel: UILabel!
    
    // Buttons to start and stop sessions
    @IBOutlet weak var trackButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func switchState(_ sender: UIButton) {
        switch(self.state) {
        case 0:
            setup()
            sender.setTitle("Stop", for: .normal)
            self.state = 1
        case 1:
            stopTracking()
            sender.setTitle("Restart", for: .normal)
            self.state = 2
        case 2:
            sessionStatusLabel.text = "Session completed"
            sender.setTitle("Start", for: .normal)
            self.state = 0
        default: // Should never happen
            print("Unexpected case: \(self.state)")
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        
//        print("-------Results-------")
//        print("Starting Theta: \(startTheta)")
//        print("Ending Theta: \(endTheta)")
//        print("Distance Traveled: \(distance)")
        
        let dTheta = abs(startTheta - endTheta)
        let estVeer = abs(cos(dTheta) * Double(distance))
        
//        print("Estimated Veering: \(estVeer)")
        
        veeringLabel.text = "Estimated Veering: \(estVeer) m, dTheta: \(dTheta.truncate(places: 2))°"
    }
    
    func startCountingSteps() {
        pedometer.startUpdates(from: Date()) {
          [weak self] pedometerData, error in
          guard let pedometerData = pedometerData, error == nil else { return }
            // Runs concurrently
            DispatchQueue.main.async {
                self?.distance = Int(truncating: pedometerData.distance ?? 0)
            }
        }
    }
    
    func setup() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
        
        sessionStatusLabel.text = "Session in progress"
        
        startCountingSteps()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Consider averaging the last 5 values of this - to ensure that there are no outliers?
        let curr = newHeading.magneticHeading
        
        if (startTheta == -1.0) {
            startTheta = curr
        }
        endTheta = curr // Whatever the last value of curr is -> Is where we end
    }
}

extension Double {
    func truncate(places : Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * self) / pow(10.0, Double(places)))
    }
}
