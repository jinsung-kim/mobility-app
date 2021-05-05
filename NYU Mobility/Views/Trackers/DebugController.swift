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
    // Used as a method of regularization when the graphic is drawn
    // (to ensure that it fits into the frame)
    var totalTime: Int = 0
    // Used to store the history of each interval to draw out
    var timeIntervals: [Int] = []
    // Used to store the history of the orientation to calculate veering
    var compassTrackings: [Double] = []
    
    // Buttons to start and stop sessions
    @IBOutlet weak var trackButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
    }
    
    // Edge case: If the session runs so long that this is called
    // -> Simply clear the data
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
        case 0: // Start tracking
            setup()
            currTime = getCurrentMillis()
            sender.setTitle("Stop", for: .normal)
            self.state = 1
        case 1: // Stops tracking -> session is complete
            stopTracking()
            sender.setTitle("See Results", for: .normal)
            self.state = 2
        case 2: // This is the default resting state
            // Performing the segue over to the results controller
            performSegue(withIdentifier: "ShowVeeringResults", sender: nil)
            sender.setTitle("Start", for: .normal)
            self.state = 0
        default: // Should never happen
            print("Unexpected case: \(self.state)")
        }
    }
    
    /**
     After the session is completed - the location manager is stopped
     (stopping the steps, distance, and compass trackers)
     Then, the calculations are made and veering is detected (either in left and right)
     Finally, the draw veering model function is called -> which will draw out the graphic for the actual veering
     */
    func stopTracking() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
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
    // This is the main function that is used when the button is pressed
    // (IBAction handler)
    func setup() {
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        
        startCountingSteps()
        
        // If multiple sessions done at once -> we want to clear out the area
        // for the new session (no overwriting)
        clearSessionData()
    }
    
    // Called everytime the compass is moved at least
    // 1 degrees in a particular direction
    // We get a time stamp -> And then we also store the new compass value
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        // Consider averaging the last 5 values of this -
        // to ensure that there are no outliers?
        let curr = newHeading.magneticHeading
        
        compassTrackings.append(curr)
        
        // Used to get the time split
        let now = getCurrentMillis()
        let timeSplit = now - currTime!
        totalTime += timeSplit
        
        timeIntervals.append(timeSplit)
        
        currTime = now
    }
    
    // Clears all the session data -> mainly used in clearVeeringModel()
    func clearSessionData() {
        compassTrackings.removeAll() // Removes the previous session's trackers
        timeIntervals.removeAll() // Clears time slots
        totalTime = 0
        distance = 0
    }
    
    // Data to send when the user gets redirected to see their results
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowVeeringResults" {
            if let next = segue.destination as? VeeringResultsController {
                next.distance = self.distance
                next.totalTime = self.totalTime
                next.timeIntervals = self.timeIntervals
                next.compassTrackings = self.compassTrackings
            }
        }
    }
}
