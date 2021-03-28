//
//  SettingsController.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 3/28/21.
//

import UIKit

class SettingsController: UITableViewController {
    
    // Buttons to make changes
    @IBOutlet weak var changeEmailButton: UIButton!
    @IBOutlet weak var voiceoverSwitch: UISwitch!
    
    let defaults = UserDefaults.standard
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        voiceoverSwitch.isOn = defaults.bool(forKey: "voiceover")
    }
    
    @IBAction func voiceoverSwitched(_ sender: UISwitch) {
        defaults.setValue(sender.isOn, forKey: "voiceover")
    }
    
    @IBAction func changeEmailPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Change Email", message: """
                                        Your email is needed to label files \
                                        (No emails will be sent to you or from you)
                                      """, preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "Change Email", style: .default, handler: { alert -> Void in
            let newEmail = alertController.textFields![0] as UITextField
            let v = newEmail.text! // The raw email input
            self.defaults.setValue(v, forKey: "email")
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in })
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Ex: test@gmail.com"
        }

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
