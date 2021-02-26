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

    override func viewDidLoad() {
        super.viewDidLoad()
        getLocationPermission()
        getStepCountPerDay(completion: { steps in
            print(steps)
        })
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
    
    func getStepCountPerDay(completion: @escaping (_ count: Double) -> Void){

        guard let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)
            else {
                return
        }
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.day = 1

        var anchorComponents = calendar.dateComponents([.day, .month, .year], from: Date())
        anchorComponents.hour = 0
        let anchorDate = calendar.date(from: anchorComponents)

        let stepsCumulativeQuery = HKStatisticsCollectionQuery(quantityType: sampleType, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate!, intervalComponents: dateComponents
        )

        // Set the results handler
        stepsCumulativeQuery.initialResultsHandler = {query, results, error in
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: 0, to: endDate, wrappingComponents: false)
            if let myResults = results {
                myResults.enumerateStatistics(from: startDate!, to: endDate as Date) { statistics, stop in
                    if let quantity = statistics.sumQuantity() {
                        let date = statistics.startDate
                        let steps = quantity.doubleValue(for: HKUnit.count())
                        print("\(date): steps = \(steps)")
                        completion(steps)
                        // NOTE: If you are going to update the UI do it in the main thread
                        DispatchQueue.main.async {
                            // Update UI components
                        }
                    }
                } // End block
            } // End if let
        }
        HKHealthStore().execute(stepsCumulativeQuery)
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
