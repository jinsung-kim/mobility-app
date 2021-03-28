//
//  Tracker3Controller.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import UIKit
import CoreLocation
import CoreMotion

class Tracker3Controller: UIViewController,
                          CLLocationManagerDelegate {
    
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var startButton: UIButton!
    
    var saved: String = ""
    var json: String = ""
    var json2: String = ""
    
    // Movement tracking managers (copied from SpecialistTrackingController.swift)
    
    // Used to track pedometer when saving data
    private var steps: Int32 = 0
    private var prevSteps: Int32 = 0
    private var distance: Int32 = 0
    private var prevDis: Int32 = 0
    private var startTime: Date = Date()
    
    // Gyro Sensor
    private let motionManager: CMMotionManager = CMMotionManager()
    // Used to store all x, y, z values
    private var gyroDict: [String: [Double]] = ["x": [], "y": [], "z": []]
    private var accelDict: [String: [Double]] = ["x": [], "y": [], "z": []]
    
    // GPS Location Services
    var coords: [CLLocationCoordinate2D] = []
    private let locationManager: CLLocationManager = CLLocationManager()
    private var locationArray: [String: [Double]] = ["long": [], "lat": []]
    
    // Used for creating the JSON
    var points: [Point] = []
    var points2: [Gyro] = []
    
    // Pedometer object - used to trace each step
    private let activityManager: CMMotionActivityManager = CMMotionActivityManager()
    private let pedometer: CMPedometer = CMPedometer()
    
    // Pace trackers
    private var currPace: Double = 0.0
    private var avgPace: Double = 0.0
    private var currCad: Double = 0.0
    
    var state: Int = 0 // Treat as flag for state (0 - not tracking, 1 - tracking)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createCircleView()
        
        // Screen will not go to sleep with this line below
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Instructions Page Redirect setup
        getLocationPermission()
    }
    
    // Main trigger event that determines the state that the app is in
    @IBAction func buttonPressed(_ sender: BubbleButton) {
        switch(self.state) {
        case 0:
            startTracking()
            sender.setTitle("Stop", for: .normal)
            self.state = 1
        case 1:
            stopTracking()
            sender.setTitle("Share", for: .normal)
            self.state = 2
        case 2:
            // Redirects to the share button
            self.performSegue(withIdentifier: "Share3", sender: self)
            clearData()
            sender.setTitle("Start", for: .normal)
            self.state = 0
        default: // Should never happen
            print("Unexpected case: \(self.state)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ShareController
        vc.saved = saved
        vc.json = json
        vc.json2 = json2
    }
    
    func createCircleView() {
        circleView.layer.cornerRadius = 120 // half the width / height (of the view)
        circleView.backgroundColor = Colors.nyuBackground
    }
    
    func getLocationPermission() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Used to include the file name, since we want to avoid using . within the file name
    func getSafeEmail() -> String{
        let email: String = UserDefaults.standard.string(forKey: "email")!
        return email.replacingOccurrences(of: "@", with: "-")
                    .replacingOccurrences(of: ".", with: "-")
    }
    
    /**
        Generates the tag for the video and matching JSON file
        Using the format: yyyy-MM-dd-hh-mm-ss
        Ex: 2020-09-04-12-23-43-jinkim-nyu-edu -> Used in generate URL for .json
     */
    func safeTagGenerator() -> String {
        var res: String = ""
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        res = df.string(from: startTime)
        // Safe value
        let email: String = getSafeEmail()
        res = res + "-" + email
        return res
    }
    
    // Location Tracking Functions
    
    // Continuously gets the location of the user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for _ in locations { // _ -> currentLocation
            if let location: CLLocation = locationManager.location {
                // Coordinate object
                let coordinate: CLLocationCoordinate2D = location.coordinate
                coords.append(coordinate)
                // ... proceed with the location and coordinates
                if (locationArray["lat"] == nil) {
                    locationArray["lat"] = [coordinate.latitude]
                    locationArray["long"] = [coordinate.longitude]
                } else {
                    locationArray["lat"]!.append(coordinate.latitude)
                    locationArray["long"]!.append(coordinate.longitude)
                }
            }
            // Looks like this when debugged (city bike ride):
            // (Function): <+37.33144466,-122.03075535> +/- 30.00m
            // (speed 6.01 mps / course 180.98) @ 3/13/20, 8:55:48 PM Pacific Daylight Time
        }
    }
    
    // Pedometer Tracking
    
    /**
        Starts the gyroscope tracking, GPS location tracking, and pedometer object
        Assumes that location permissions and motion permissions have already been granted
        Changes the color of the UIView to green (indicating that it is in go mode)
        - Parameters:
            - fileName: The name of the file that should be played
     */
    func startTracking() {
        locationManager.startUpdatingLocation()
        startGyro()
        startAccel()
        startUpdating()
        saveData(currTime: Date())
    }
    
    /**
        Stops tracking the gyroscope, GPS location, and pedometer object
        Assumes that the previously stated managers are running
     */
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        stopGyros()
        stopAccel()
        stopUpdating()
        saveData(currTime: Date())
        saved = safeTagGenerator()
        json = generateJSONString()
        json2 = generateJSON2String()
    }
    
    func stopUpdating() { pedometer.stopUpdates() }
    
    // Pedometer Functions
    
    func startUpdating() {
        if CMMotionActivityManager.isActivityAvailable() {
            startTrackingActivityType()
        }

        if CMPedometer.isStepCountingAvailable() {
            startCountingSteps()
        }
    }
    
    func startTrackingActivityType() {
        activityManager.startActivityUpdates(to: OperationQueue.main) { _ in }
    }
    
    func startCountingSteps() {
        pedometer.startUpdates(from: Date()) {
          [weak self] pedometerData, error in
          guard let pedometerData = pedometerData, error == nil else { return }

            // Runs concurrently
            DispatchQueue.main.async {
                self?.saveData(currTime: Date())
                self?.distance = Int32(truncating: pedometerData.distance ?? 0)
                self?.steps = Int32(truncating: pedometerData.numberOfSteps)
                self?.avgPace = Double(truncating: pedometerData.averageActivePace ?? 0)
                self?.currPace = Double(truncating: pedometerData.currentPace ?? 0)
                self?.currCad = Double(truncating: pedometerData.currentCadence ?? 0)
            }
        }
    }
    
    func dateToString(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let dateString = formatter.string(from: date)
        return dateString
    }
    
    /**
        Saves the given data into the stack, and clears out the gyroscope data to start taking values again
        - Parameters:
            - currTime: Date in which the data has been tracked
     */
    func saveData(currTime: Date) {
        // JSON array implementation (See Point.swift for model)
        
        
        points.append(Point(dateToString(), steps,
                            distance, avgPace, currPace,
                            currCad, locationArray,
                            steps - prevSteps, distance - prevDis))
        points2.append(Gyro(dateToString(), gyroDict, accelDict))
        
        prevSteps = steps
        prevDis = distance
        
        gyroDict.removeAll()
        accelDict.removeAll()
        locationArray.removeAll()
        
        locationArray = ["long": [], "lat": []]
        gyroDict = ["x": [], "y": [], "z": []]
        accelDict = ["x": [], "y": [], "z": []]
    }
    
    // Generate JSON in Dictionary form
    func generateJSON() -> [[String: Any]] {
        let dicArray = points.map { $0.convertToDictionary() }
        return dicArray
    }
    
    func generateJSON2() -> [[String: Any]] {
        let jsonArray = points2.map { $0.convertToDictionary2() }
        return jsonArray
    }
    
    // Generate JSON in String form
    func generateJSONString() -> String {
        let dicArray = points.map { $0.convertToDictionary() }
        if let data = try? JSONSerialization.data(withJSONObject: dicArray, options: .prettyPrinted) {
            let str = String(bytes: data, encoding: .utf8)
            return str!
        }
        return "There was an error generating the JSON file" // shouldn't ever happen
    }
    
    func generateJSON2String() -> String {
        let jsonArray = points2.map { $0.convertToDictionary2() }
        if let data = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted) {
            let str = String(bytes: data, encoding: .utf8)
            return str!
        }
        return "There was an error generating the Gyroscope JSON file"
    }

    func clearData() {
        points.removeAll()
        points2.removeAll()
    }
    
    // Gyroscope Functions
        
    // Starts the gyroscope once it is confirmed to be available
    func startGyro() {
        if motionManager.isGyroAvailable {
            // Set to update 5 times a second
            self.motionManager.gyroUpdateInterval = 0.2
            self.motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
                if let gyroData = data {
                    if (self.gyroDict["x"] == nil) { // No entries for this point yet
                        self.gyroDict["x"] = [gyroData.rotationRate.x]
                        self.gyroDict["y"] = [gyroData.rotationRate.y]
                        self.gyroDict["z"] = [gyroData.rotationRate.z]
                    } else { // We know there are already values inserted
                        self.gyroDict["x"]!.append(gyroData.rotationRate.x)
                        self.gyroDict["y"]!.append(gyroData.rotationRate.y)
                        self.gyroDict["z"]!.append(gyroData.rotationRate.z)
                    }
                }
            }
        }
    }
    
    // Stops the gyroscope (assuming that it is available)
    func stopGyros() { self.motionManager.stopGyroUpdates() }
    
    // Accelerometer Functions
    
    // Starts the accelerometer (assuming that it is available)
    func startAccel() {
        if motionManager.isAccelerometerAvailable {
            self.motionManager.accelerometerUpdateInterval = 0.2
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                if let accelData = data {
                    if (self.accelDict["x"] == nil) { // No entries for this point yet
                        self.accelDict["x"] = [accelData.acceleration.x]
                        self.accelDict["y"] = [accelData.acceleration.y]
                        self.accelDict["z"] = [accelData.acceleration.z]
                    } else { // We know there are already values inserted
                        self.accelDict["x"]!.append(accelData.acceleration.x)
                        self.accelDict["y"]!.append(accelData.acceleration.y)
                        self.accelDict["z"]!.append(accelData.acceleration.z)
                    }
                }
            }
        }
    }
    
    // Stops the accelerometer (assuming that it is available)
    func stopAccel() { self.motionManager.stopAccelerometerUpdates() }
    
}
