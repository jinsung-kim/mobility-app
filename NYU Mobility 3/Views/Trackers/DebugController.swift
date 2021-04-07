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
import CoreMotion
import GLKit

class DebugController: UIViewController {
    
    // Accelerometer data printed live
    var a_x: [CGFloat] = []
    var a_y: [CGFloat] = []
    var a_z: [CGFloat] = []
    
    var g_x: [CGFloat] = []
    var g_y: [CGFloat] = []
    var g_z: [CGFloat] = []
    
    // Gyro Sensor
    private let motionManager: CMMotionManager = CMMotionManager()
    // Used to store all x, y, z values
    private var gyroDict: [String: [Double]] = ["x": [], "y": [], "z": []]
    private var accelDict: [String: [Double]] = ["x": [], "y": [], "z": []]
    
    // Pedometer object - used to trace each step
    private let activityManager: CMMotionActivityManager = CMMotionActivityManager()
    private let pedometer: CMPedometer = CMPedometer()
    
    var state: Int = 0 // Treat as flag for state (0 - not tracking, 1 - tracking)
    
    var xT: CGFloat = 0.0
    var yT: CGFloat = 0.0
    var zT: CGFloat = 0.0
    
    var xTa: CGFloat = 0.0
    var yTa: CGFloat = 0.0
    var zTa: CGFloat = 0.0
    
    // Buttons to start and stop sessions
    @IBOutlet weak var trackButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func switchState(_ sender: UIButton) {
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
            sender.setTitle("Start", for: .normal)
            self.state = 0
        default: // Should never happen
            print("Unexpected case: \(self.state)")
        }
    }
    
    func startTracking() {
        startGyro()
        startAccel()
        startUpdating()
//        saveData(currTime: Date())
    }
    
    /**
        Stops tracking the gyroscope, GPS location, and pedometer object
        Assumes that the previously stated managers are running
     */
    func stopTracking() {
        stopGyros()
        stopAccel()
        stopUpdating()
//        saveData(currTime: Date())
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
        pedometer.startUpdates(from: Date()) { _,_ in
//          [weak self] pedometerData, error in
//          guard let pedometerData = pedometerData, error == nil else { return }

            // Runs concurrently
//            DispatchQueue.main.async {
//                self?.saveData(currTime: Date())
//            }
        }
    }
    
    func dateToString(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let dateString = formatter.string(from: date)
        return dateString
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
                        self.g_x = [CGFloat(gyroData.rotationRate.x)]
                        self.g_x = [CGFloat(gyroData.rotationRate.y)]
                        self.g_y = [CGFloat(gyroData.rotationRate.z)]
                    } else { // We know there are already values inserted
                        self.g_x.append(CGFloat(gyroData.rotationRate.x))
                        self.g_y.append(CGFloat(gyroData.rotationRate.y))
                        self.g_z.append(CGFloat(gyroData.rotationRate.z))
                    }
                    self.xT += CGFloat(gyroData.rotationRate.x)
                    self.yT += CGFloat(gyroData.rotationRate.y)
                    self.zT += CGFloat(gyroData.rotationRate.z)
//                    print(CGFloat(gyroData.rotationRate.y))
//                    print(CGFloat(gyroData.rotationRate.z))
                }
            }
        }
    }
    
    // Stops the gyroscope (assuming that it is available)
    func stopGyros() {
        self.motionManager.stopGyroUpdates()
        
        print("xT: \(self.xT)")
        print("yT: \(self.yT)")
        print("zT: \(self.zT)")
        
        print("xTa: \(self.xTa)")
        print("yTa: \(self.yTa)")
        print("zTa: \(self.zTa)\n")
        
        self.xT = 0.0
        self.yT = 0.0
        self.zT = 0.0
        
        self.xTa = 0.0
        self.yTa = 0.0
        self.zTa = 0.0
    }
    
    // Accelerometer Functions
    
    // Starts the accelerometer (assuming that it is available)
    func startAccel() {
        if motionManager.isAccelerometerAvailable {
            self.motionManager.accelerometerUpdateInterval = 0.2
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                if let accelData = data {
                    if (self.accelDict["x"] == nil) { // No entries for this point yet
                        self.a_x = [CGFloat(accelData.acceleration.x)]
                        self.a_x = [CGFloat(accelData.acceleration.y)]
                        self.a_y = [CGFloat(accelData.acceleration.z)]
                    } else { // We know there are already values inserted
                        self.a_x.append(CGFloat(accelData.acceleration.x))
                        self.a_y.append(CGFloat(accelData.acceleration.y))
                        self.a_z.append(CGFloat(accelData.acceleration.z))
                    }
                    
                    self.xTa += CGFloat(accelData.acceleration.x)
                    self.yTa += CGFloat(accelData.acceleration.y)
                    self.zTa += CGFloat(accelData.acceleration.z)
                }
            }
        }
    }
    
    // Stops the accelerometer (assuming that it is available)
    func stopAccel() { self.motionManager.stopAccelerometerUpdates() }
}

extension CMDeviceMotion {

    func userAccelerationInReferenceFrame() -> CMAcceleration {

        let origin = userAcceleration
        let rotation = attitude.rotationMatrix
        let matrix = rotation.inverse()

        var result = CMAcceleration()
        result.x = origin.x * matrix.m11 + origin.y * matrix.m12 + origin.z * matrix.m13;
        result.y = origin.x * matrix.m21 + origin.y * matrix.m22 + origin.z * matrix.m23;
        result.z = origin.x * matrix.m31 + origin.y * matrix.m32 + origin.z * matrix.m33;

        return result
    }

    func gravityInReferenceFrame() -> CMAcceleration {

        let origin = self.gravity
        let rotation = attitude.rotationMatrix
        let matrix = rotation.inverse()

        var result = CMAcceleration()
        result.x = origin.x * matrix.m11 + origin.y * matrix.m12 + origin.z * matrix.m13;
        result.y = origin.x * matrix.m21 + origin.y * matrix.m22 + origin.z * matrix.m23;
        result.z = origin.x * matrix.m31 + origin.y * matrix.m32 + origin.z * matrix.m33;

        return result
    }
}

extension CMRotationMatrix {

    func inverse() -> CMRotationMatrix {

        let matrix = GLKMatrix3Make(Float(m11), Float(m12), Float(m13), Float(m21), Float(m22), Float(m23), Float(m31), Float(m32), Float(m33))
        let invert = GLKMatrix3Invert(matrix, nil)

        return CMRotationMatrix(m11: Double(invert.m00), m12: Double(invert.m01), m13: Double(invert.m02),
                            m21: Double(invert.m10), m22: Double(invert.m11), m23: Double(invert.m12),
                            m31: Double(invert.m20), m32: Double(invert.m21), m33: Double(invert.m22))

    }

}
