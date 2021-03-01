//
//  StartController.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import UIKit
import CoreMotion
import CoreLocation
import HealthKit

class StartController: UIViewController, CLLocationManagerDelegate {
    
    private let locationManager: CLLocationManager = CLLocationManager()
    
    let healthStore = HKHealthStore()
    
    // Redirects to the different versions
    @IBOutlet weak var option1Button: BubbleButton! // Video (Steps)
    @IBOutlet weak var option2Button: BubbleButton! // Video (Steps + GPS)
    @IBOutlet weak var option3Button: BubbleButton! // No Video
    
    var stepHistory: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        getLocationPermission()
        getHealthKitPermission()
    }
    
    func getLocationPermission() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    // Used to ensure that
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // Registers button clicks + validates + redirects
    @IBAction func button1Pressed(_ sender: Any) {
        if (validateEmail()) {
            performSegue(withIdentifier: "Tracker1", sender: self)
        }
    }
    
    @IBAction func button2Pressed(_ sender: Any) {
        if (validateEmail()) {
            performSegue(withIdentifier: "Tracker2", sender: self)
        }
    }
    
    @IBAction func button3Pressed(_ sender: Any) {
        if (validateEmail()) {
            performSegue(withIdentifier: "Tracker3", sender: self)
        }
    }
    
    /**
        Ensures that there is a valid email that exists so that files can be labeled properly
     */
    func validateEmail() -> Bool {
        if (UserDefaults.standard.string(forKey: "email")! == "") {
            showInputDialog(title: "Enter your email",
                            subtitle: """
                                        Your email is needed to label files \
                                        (No emails will be sent to you or from you)
                                      """,
                            actionTitle: "Add",
                            cancelTitle: "Cancel",
                            inputPlaceholder: "Ex: test@gmail.com",
                            inputKeyboardType: .emailAddress, actionHandler:
                                { (input: String?) in
                                    self.save("email", input ?? "")
                                })
        } else { // If email is found -> tracking can be started
            return true
        }
        return false
    }
    
    func save(_ key: String, _ value: String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: "\(key)")
    }
    
    func getHealthKitPermission() {

        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        let stepsCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!

        self.healthStore.requestAuthorization(toShare: [], read: [stepsCount]) { (success, error) in
            if success {
//                print("Permission accepted.")
                self.getTodaySteps()
            }
            else {
                if error != nil {
                    print(error ?? "")
                }
//                print("Permission denied.")
            }
        }
    }
    
    func getTodaySteps() {
        let startDate = Date().addingTimeInterval(-3600 * 24 * 7)
        let endDate = Date()

        let predicate = HKQuery.predicateForSamples(
          withStart: startDate,
          end: endDate,
          options: [.strictStartDate, .strictEndDate]
        )

        // Interval is 1 day
        var interval = DateComponents()
        interval.day = 1

        // Start from midnight
        let calendar = Calendar.current
        let anchorDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())

        let query = HKStatisticsCollectionQuery(
          quantityType: HKSampleType.quantityType(forIdentifier: .stepCount)!,
          quantitySamplePredicate: predicate,
          options: .cumulativeSum,
          anchorDate: anchorDate!,
          intervalComponents: interval
        )

        query.initialResultsHandler = { query, results, error in
          guard let results = results else {
            return
          }

          results.enumerateStatistics(
            from: startDate,
            to: endDate,
            with: { (result, stop) in
                let totalForDay = result.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                self.stepHistory.append(Int(totalForDay))
            }
          )
            print(self.stepHistory)
        }
        healthStore.execute(query)
    }
}

extension UIViewController {
    func showInputDialog(title: String? = nil,
                         subtitle: String? = nil,
                         actionTitle: String? = "Add",
                         cancelTitle: String? = "Cancel",
                         inputPlaceholder: String? = nil,
                         inputKeyboardType: UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {

        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler))

        self.present(alert, animated: true, completion: nil)
    }
}
