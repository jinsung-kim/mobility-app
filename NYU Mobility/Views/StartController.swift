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
        addSettingsButton()
        addDebugButton()
    }
    
    // Adds buttons to the navigation bar for appropriate redirects
    func addSettingsButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Settings",
                                                                      style: .done,
                                                                      target: self,
                                                                      action: #selector(self.rightClick(sender:)))
    }
    
    func addDebugButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Debug",
                                                                     style: .done,
                                                                     target: self,
                                                                     action: #selector(self.leftClick(sender:)))
    }
    
    // Redirects to the appropriate view controller
    @objc func rightClick(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "GoToSettings", sender: self)
    }
    
    @objc func leftClick(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ToDebug", sender: self)
    }
    
    /// Tries to get authorization before the tracking begins to ensure that it is set up
    func getLocationPermission() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

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
    
    /// Accessibility (Sound) Features -> Only triggered if the setting is enabled
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
