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

// Used to determine how the veering was done
enum Direction {
    case left
    case right
    case straight
}

class DebugController: UIViewController, CLLocationManagerDelegate {
    
    var state: Int = 0 // Treat as flag for state (0 - not tracking, 1 - tracking)
    
    private let locationManager: CLLocationManager = CLLocationManager()
    private let pedometer: CMPedometer = CMPedometer()
    
    var distance: Int = 0
    
    @IBOutlet weak var veeringModel: UIView!
    
    // Labels for debugging process
    @IBOutlet weak var sessionStatusLabel: UILabel!
    @IBOutlet weak var veeringLabel: UILabel!
    
    // Buttons to start and stop sessions
    @IBOutlet weak var trackButton: UIButton!
    
    // Orientation Array
    private var compassTrackings: [Double] = []
    
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
        
        // Edge cases
        if (compassTrackings.count == 0) { // No calculations to make if session was too short or perfect
            veeringLabel.text = "Session was too short to detect veering"
            return
        } else if (compassTrackings.count == 1) {
            veeringLabel.text = "No veering was detected in this session"
            return
        }
        
        // Left and right derivative counters
        var lC: Int = 0, rC: Int = 0
        var prev: Double = compassTrackings.first!, curr: Double = 0.0
        
        for i in 1 ..< compassTrackings.count {
            curr = compassTrackings[i]
            if (prev >= 0 && prev < 5 && curr > 355) { // Crossing North threshold
                lC += 1
            } else if (prev > 355 && curr >= 0 && curr < 5) {
                rC += 1
            } else if (curr > prev) {
                rC += 1
            } else {
                lC += 1
            }
            prev = compassTrackings[i] // Update previous to be current after
        }
        
        // Can force unwrap since we are now guaranteed to have users:
        let startTheta = compassTrackings.first!
        let endTheta = compassTrackings.last!
        
        let dTheta = abs(startTheta - endTheta)
        let estVeer = abs(cos(dTheta) * Double(distance))
        
        veeringLabel.text = "Estimated Veering: \(estVeer.truncate(places: 2)) m, dTheta: \(dTheta.truncate(places: 2))°"
        
        // This indicates veering to the left - as the end is a smaller value
        if (lC > rC) {
            drawVeeringModel(Direction.left)
        } else if (rC > lC) {
            drawVeeringModel(Direction.right)
        } else {
            // No Veering
            drawVeeringModel(Direction.straight)
        }
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
        
        clearVeeringModel()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Consider averaging the last 5 values of this - to ensure that there are no outliers?
        let curr = newHeading.magneticHeading
        
        compassTrackings.append(curr)
    }
    
    func drawVeeringModel(_ direction: Direction) {
        let heightWidth = veeringModel.frame.size.width
        let path = CGMutablePath()
        
        if (direction == .left) {
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            path.addLine(to: CGPoint(x: 0, y: 0))
            
            let shape = CAShapeLayer()
            shape.path = path
            shape.fillColor = UIColor.red.cgColor // Color that the triangle is filled in

            veeringModel.layer.insertSublayer(shape, at: 0)
        } else if (direction == .right) {
            path.move(to: CGPoint(x: heightWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: heightWidth, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: 0))
            
            let shape = CAShapeLayer()
            shape.path = path
            shape.fillColor = UIColor.blue.cgColor // Color that the triangle is filled in

            veeringModel.layer.insertSublayer(shape, at: 0)
        } else { // Straight
            path.move(to: CGPoint(x: heightWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            let shape = CAShapeLayer()
            shape.path = path
            shape.fillColor = UIColor.green.cgColor // Color that the line is filled in

            veeringModel.layer.insertSublayer(shape, at: 0)
        }
    }
    
    func clearVeeringModel() {
        guard let sublayers = veeringModel.layer.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
    }
}

extension Double {
    func truncate(places : Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * self) / pow(10.0, Double(places)))
    }
}
