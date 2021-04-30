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

// Used to determine what direction the veering was done
enum Direction {
    case left
    case right
    case straight
}

/// This is the view controller that controls the veering session
class DebugController: UIViewController, CLLocationManagerDelegate {
    
    // Treat as flag for state:
    // 0 - start tracking
    // 1 - stop tracking
    // 2 - show results
    var state: Int = 0
    
    // Managers that will be called when tracking begins
    private let locationManager: CLLocationManager = CLLocationManager()
    private let pedometer: CMPedometer = CMPedometer()
    
    // Veering in a particular direction
    var distance: Int = 0
    
    // Used to calculate time between two compass data points
    var currTime: Int!
    // Used as a method of regularization when the graphic is drawn (to ensure that it fits into the frame)
    var totalTime: Int = 0
    // Used to store the history of each interval to draw out
    var timeIntervals: [Int] = []
    
    // CONSTANT for how wide the veering should be - this should not be too high
    // to avoid clipping
    let X_MOVE: Double = 25.0
    
    // CONSTANT for how tall the veering height should be - this should also not be too high
    // to avoid clipping
    let Y_MOVE: Double = 10.0
    
    // The view where the graphic is drawn to show veering
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
    
    // Edge case: If the session runs so long that this is called -> Simply clear the data
    // Ideally this would never happen
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     The state of the tracking session.
     0 - Default state (not recording or tracking anything - but transitions into starting the session)
     1 - Tracking is in session. Once this is pressed the session is stopped
     2 - Completes the session and adds the information about the veering (d theta)
     */
    @IBAction func switchState(_ sender: UIButton) {
        switch(self.state) {
        case 0:
            setup()
            currTime = getCurrentMillis()
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
    
    /**
     After the session is completed - the location manager is stopped (stopping the steps, distance, and compass trackers)
     Then, the calculations are made and veering is detected (either in left and right)
     Finally, the draw veering model function is called -> which will draw out the graphic for the actual veering
     */
    func stopTracking() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        
        // Edge cases
        // No calculations to make if session was too short or perfect
        if (compassTrackings.count == 0) {
            veeringLabel.text = "Session was too short to detect veering"
            return
        // If there is only one compass entry -> There was no veering
        // Or the session was too short
        } else if (compassTrackings.count == 1) {
            veeringLabel.text = "No veering was detected in this session"
            return
        }
        
        // Left and right derivative counters
        // We increment these counters for each left + right movement
        // The overall count of these counters will determine whether
        // veering was to the left or to the right
        var lC: Int = 0, rC: Int = 0
        var prev: Double = compassTrackings.first!, curr: Double = 0.0
        
        for i in 1 ..< compassTrackings.count {
            curr = compassTrackings[i]
            if (prev >= 0 && prev < 5 && curr > 355) { // Crossing North threshold (l -> r)
                lC += 1
            } else if (prev > 355 && curr >= 0 && curr < 5) { // Crossing (r -> l)
                rC += 1
            } else if (curr > prev) {
                rC += 1
            } else {
                lC += 1
            }
            prev = compassTrackings[i] // Update previous to be current after
        }
        
        // Can force unwrap since we are now guaranteed to have values:
        let startTheta = compassTrackings.first!
        let endTheta = compassTrackings.last!
        
        // Currently the way we detect the difference in theta (veering angle)
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
    
    // Called when we want to start counting the steps
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
    
    // Calls all the functions needed to start a session
    // This is the main function that is used when the button is pressed (IBAction handler)
    func setup() {
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            self.locationManager.startUpdatingLocation()
            self.locationManager.startUpdatingHeading()
        }
        
        sessionStatusLabel.text = "Session in progress"
        
        startCountingSteps()
        
        // If multiple sessions done at once -> we want to clear out the area
        // for the new session (no overwriting)
        clearVeeringModel()
    }
    
    // Called everytime the compass is moved at least 1 degrees in a particular direction
    // We get a time stamp -> And then we also store the new compass value
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Consider averaging the last 5 values of this - to ensure that there are no outliers?
        let curr = newHeading.magneticHeading
        
        compassTrackings.append(curr)
        
        // Used to get the time split
        let now = getCurrentMillis()
        let timeSplit = now - currTime!
        totalTime += timeSplit
        
        timeIntervals.append(timeSplit)
        
        currTime = now
    }
    
    /**
     The actual function that draws out the veering once the direction is determined in stopTracking()
     There are two cases (in the current build):
        - Left -> Red color triangle
        - Right -> Blue color triangle
     
     There are also a lot of visual calculations that are made using the arrays for orientation and time stamps
     */
    func drawVeeringModel(_ direction: Direction) {
        let heightWidth = veeringModel.frame.size.width
        let path = CGMutablePath()
        
        let hLen: Int = compassTrackings.count
        let changeY: Double = Double(heightWidth) / Double(hLen)
        var deltaY: Double = 0.0
        
        // Used to move the path a certain amount based on prior compass
        // trackings
        var newX: Double = Double(heightWidth) / 2.0
        var newY: Double = Double(heightWidth)
        
        var xChanges: [Double] = []
        var xTotal: Double = 0.0
        
        if (direction == .left) {
            path.move(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            // This is where the calculations are made
            for i in 1 ..< hLen {
                let deltaTheta: CGFloat = CGFloat(compassTrackings[i]) - CGFloat(compassTrackings[i - 1])
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                if (deltaTheta < 0) { // Going right
                    let c = Double((Double(deltaY) * Double(tan(abs(deltaTheta)))))
                    xTotal += c
                    xChanges.append(-c)
                } else { // Going left
                    let c = Double((Double(deltaY) * Double(tan(deltaTheta))))
                    xTotal += c
                    xChanges.append(c)
                }
            }
            
            // Where the path is actually drawn
            for i in 1 ..< xChanges.count {
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                newY -= deltaY
                newX += (xChanges[i] / xTotal) * X_MOVE
                path.addLine(to: CGPoint(x: newX, y: newY))
            }
            
            // This completes the triangle
            path.addLine(to: CGPoint(x: newX, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            let shape = CAShapeLayer()
            shape.path = path
            shape.fillColor = UIColor.red.cgColor // Color that the triangle is filled in
            
            veeringModel.layer.insertSublayer(shape, at: 0)
        } else if (direction == .right) {
            
            path.move(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            // This is where the calculations are made
            for i in 1 ..< hLen {
                let deltaTheta: CGFloat = CGFloat(compassTrackings[i]) - CGFloat(compassTrackings[i - 1])
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                
                if (deltaTheta < 0) { // Going right
                    let c = Double((Double(deltaY) * Double(tan(abs(deltaTheta)))))
                    xTotal += c
                    xChanges.append(c)
                } else { // Going left
                    let c = Double((Double(deltaY) * Double(tan(deltaTheta))))
                    xTotal += c
                    xChanges.append(c)
                }
            }
            
            // Where the path is actually drawn
            for i in 1 ..< xChanges.count {
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                newY -= deltaY
                newX += (xChanges[i] / xTotal) * X_MOVE
                path.addLine(to: CGPoint(x: newX, y: newY))
            }

            // This completes the triangle
            path.addLine(to: CGPoint(x: newX, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            let shape = CAShapeLayer()
            shape.path = path
            shape.fillColor = UIColor.blue.cgColor // Color that the triangle is filled in

            veeringModel.layer.insertSublayer(shape, at: 0)
        }
//        print(timeIntervals)
    }
    
    /**
     This function is used to clear the veering model and all of its corresponding variables
     This includes the compass trackings, time interval trackings, and the total time that is an
     accumulated sum
     */
    func clearVeeringModel() {
        guard let sublayers = veeringModel.layer.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
        clearSessionData()
    }
    
    // Clears all the session data -> mainly used in clearVeeringModel()
    func clearSessionData() {
        compassTrackings.removeAll() // Removes the previous session's trackers
        timeIntervals.removeAll() // Clears time slots
        totalTime = 0
    }
}
