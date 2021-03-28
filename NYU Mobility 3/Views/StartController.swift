//
//  StartController.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import UIKit
import CoreMotion
import CoreLocation
import AVFoundation

class StartController: UIViewController, CLLocationManagerDelegate {
    
    private let locationManager: CLLocationManager = CLLocationManager()
    
    // Redirects to the different versions
    @IBOutlet weak var option1Button: BubbleButton! // Video (Steps)
    @IBOutlet weak var option2Button: BubbleButton! // Video (Steps + GPS)
    @IBOutlet weak var option3Button: BubbleButton! // No Video
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        getLocationPermission()
        addButton()
    }
    
    func addButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Settings", style: .done, target: self, action: #selector(self.rightClick(sender:)))
    }
    
    @objc func rightClick(sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "GoToSettings", sender: self)
    }
    
    func getLocationPermission() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    // Used to ensure that the navigation bar is hidden when needed
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: animated)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: animated)
//    }

    // Registers button clicks + validates + redirects
    @IBAction func button1Pressed(_ sender: Any) {
        if (validateEmail()) {
            speakMessage("Video with just steps")
            performSegue(withIdentifier: "Tracker1", sender: self)
        }
    }
    
    @IBAction func button2Pressed(_ sender: Any) {
        if (validateEmail()) {
            speakMessage("Video with steps and GPS")
            performSegue(withIdentifier: "Tracker2", sender: self)
        }
    }
    
    @IBAction func button3Pressed(_ sender: Any) {
        if (validateEmail()) {
            speakMessage("No Video")
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
        defaults.set(value, forKey: "\(key)")
    }
    
    // Accessibility (Sound) Features
    func speakMessage(_ message: String) {
        let voiceover: Bool = defaults.bool(forKey: "voiceover")
        if voiceover {
            let utterance = AVSpeechUtterance(string: message)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

            let synth = AVSpeechSynthesizer()
            synth.speak(utterance)
        }
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
