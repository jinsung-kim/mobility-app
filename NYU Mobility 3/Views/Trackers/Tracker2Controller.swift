//
//  Tracker2Controller.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import UIKit
import CoreMotion
import CoreLocation
import AVKit
import AVFoundation

class Tracker2Controller: UIViewController,
                          AVCaptureFileOutputRecordingDelegate,
                          CLLocationManagerDelegate {
    
    @IBOutlet weak var camPreview: UIView!
    @IBOutlet weak var camButton: UIButton!
    
    let captureSession = AVCaptureSession()
    let movieOutput = AVCaptureMovieFileOutput()
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    var outputURL: URL!
    var saved: String = ""
    var json: String = ""
    var json2: String = ""
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Screen will not go to sleep with this line below
        UIApplication.shared.isIdleTimerDisabled = true
        
        getLocationPermission()
        
        if (setupSession()) {
            setupPreview()
            startSession()
        }
//        setupButton() // -> Now using actual UIButton for accessibility reasons
    }
    
    /// Sets up the camera button used to start recording/stop recording
//    func setupButton() {
//        cameraButton.isUserInteractionEnabled = true
//        let cameraButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(Tracker2Controller.startCapture))
//        cameraButton.addGestureRecognizer(cameraButtonRecognizer)
//        cameraButton.backgroundColor = UIColor.white // button is white when initialized
//        cameraButton.layer.cornerRadius = 30 // button round
//        cameraButton.layer.masksToBounds = true
//
//        camPreview.addSubview(cameraButton)
//    }
    
    /// Sets up the camera view (which will start recording)
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        camPreview.layer.addSublayer(previewLayer)
    }

    /// Sets the quality of the video and adds camera as input
    func setupSession() -> Bool {
        captureSession.sessionPreset = AVCaptureSession.Preset.medium // Change this enum to higher/lower quality
        let camera = AVCaptureDevice.default(for: AVMediaType.video)!
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if (captureSession.canAddInput(input)) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        if (captureSession.canAddOutput(movieOutput)) {
            captureSession.addOutput(movieOutput)
        }
        return true
    }
    
    func setupCaptureMode(_ mode: Int) {}
    
    /// Starts recording session
    func startSession() {
        if (!captureSession.isRunning) {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    /// Stops recording session
    func stopSession() {
        if (captureSession.isRunning) {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue { return DispatchQueue.main }
    
    /// Used to distinguish what direction the phone
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
//        let currentDevice: UIDevice = UIDevice.current
//        let orientation: UIDeviceOrientation = currentDevice.orientation
//
//        switch (orientation) {
//        case .portrait:
//            return AVCaptureVideoOrientation.portrait
//        case .landscapeRight:
//            return AVCaptureVideoOrientation.landscapeRight
//        case .landscapeLeft:
//            return AVCaptureVideoOrientation.landscapeLeft
//        case .portraitUpsideDown:
//            return AVCaptureVideoOrientation.portraitUpsideDown
//
//        default:
//            return AVCaptureVideoOrientation.portrait
//        }
        return AVCaptureVideoOrientation.portrait
    }
    
//    @objc func startCapture() {
//        startRecording()
//    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        startRecording()
    }
    
    /// Gets the directory that the video is stored in
    func getPathDirectory() -> URL {
        // Searches a FileManager for paths and returns the first one
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    func generateURL() -> URL? {
        saved = safeTagGenerator()
        let path = getPathDirectory().appendingPathComponent(saved + ".mp4")
        return path
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
        Ex: 2020-09-04-12-23-43-jinkim-nyu-edu -> Used in generate URL for .mp4 and .json
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
    
    /// Used to transfer data over to the share video
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ShareController
        vc.videoURL = outputURL
        vc.saved = saved
        vc.json = json
        vc.json2 = json2
    }
    
    func startRecording() {
        
        if (movieOutput.isRecording == false) {
            camButton.tintColor = UIColor.red
            
            startTracking()
            startTime = Date()
            
            let connection = movieOutput.connection(with: AVMediaType.video)
            
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            let device = activeInput.device
            if (device.isSmoothAutoFocusSupported) {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
            }
            
            outputURL = generateURL()
            movieOutput.startRecording(to: outputURL!, recordingDelegate: self)
            
        } else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        if (movieOutput.isRecording == true) {
            camButton.tintColor = UIColor.white
            movieOutput.stopRecording()
            stopTracking()
            clearData()
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!,
                 didStartRecordingToOutputFileAt fileURL: URL!,
                 fromConnections connections: [Any]!) {}
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            performSegue(withIdentifier: "Share2", sender: outputURL!)
        }
    }
    
    // GPS Location Services
    
    func getLocationPermission() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
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
        json = generateJSON()
        json2 = generateJSON2()
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
    
    // Generate JSON in String form
    func generateJSON() -> String {
        let dicArray = points.map { $0.convertToDictionary() }
        if let data = try? JSONSerialization.data(withJSONObject: dicArray, options: .prettyPrinted) {
            let str = String(bytes: data, encoding: .utf8)
            return str!
        }
        return "There was an error generating the JSON file" // shouldn't ever happen
    }
    
    func generateJSON2() -> String {
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
