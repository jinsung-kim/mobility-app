//
//  ShareController.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 2/5/21.
//

import UIKit
import Photos

class ShareController: UIViewController {
    
    var json: String = ""
    var json2: String = ""
    var videoURL: URL!
    var saved: String = ""
    
    @IBOutlet weak var shareButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        if (videoURL != nil) {
            saveVideoToAlbum(videoURL) { error in
                if (error != nil) {
                    print("There was an error saving the video")
                    self.alertUserSaveError()
                }
            }
        }
        writeJSONFiles() // Saves the files to the user's document directory (Files app)
    }
    
    /**
        Sends a request to the device to save the video to the camera
        - Parameters:
            - completion: The completion handler that returns whether the video save contained an error
     */
    func requestAuthorization(completion: @escaping () -> Void) {
        // Needs to ask phone for permissions
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    completion()
                }
            }
        // device has already given permission to save to the camera roll
        } else if PHPhotoLibrary.authorizationStatus() == .authorized {
            completion()
        }
    }
    
    /**
        Given the url of the video, a request is created to the photo library to be added
        - Parameters:
            - outputURL: URL that is sent to be saved
            - completion: Handles possible failures with saving the URL
        - Returns: An error if applicable
     */
    func saveVideoToAlbum(_ outputURL: URL, _ completion: ((Error?) -> Void)?) {
        requestAuthorization {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: outputURL, options: nil)
            }) { (result, error) in
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    func writeJSONFiles() {
        let file = "\(saved).json"
        let file2 = "gyro-\(saved).json"
        let content = json
        let content2 = json2
        
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(file)
        let fileURL2 = directory.appendingPathComponent(file2)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            try content2.write(to: fileURL2, atomically: true, encoding: .utf8)
        } catch {
            print("Error: \(error)")
        }
        
        let objectsToShare = [fileURL, fileURL2]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

        activityVC.setValue("Export", forKey: "subject")

        // New Excluded Activities Code
        if #available(iOS 9.0, *) {
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList,
                                                UIActivity.ActivityType.assignToContact,
                                                UIActivity.ActivityType.copyToPasteboard,
                                                UIActivity.ActivityType.mail,
                                                UIActivity.ActivityType.message,
                                                UIActivity.ActivityType.openInIBooks,
                                                UIActivity.ActivityType.postToTencentWeibo,
                                                UIActivity.ActivityType.postToVimeo,
                                                UIActivity.ActivityType.postToWeibo,
                                                UIActivity.ActivityType.print]
        // Fallback on earlier versions
        } else {
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList,
                                                UIActivity.ActivityType.assignToContact,
                                                UIActivity.ActivityType.copyToPasteboard,
                                                UIActivity.ActivityType.mail,
                                                UIActivity.ActivityType.message,
                                                UIActivity.ActivityType.postToTencentWeibo,
                                                UIActivity.ActivityType.postToVimeo,
                                                UIActivity.ActivityType.postToWeibo,
                                                UIActivity.ActivityType.print]
        }
        
        present(activityVC, animated: true, completion: nil)
    }
    
    func alertUserSaveError(message: String = "The video could not be saved to the camera roll") {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func successMessage(message: String = "The video has been uploaded successfully") {
        let alert = UIAlertController(title: "Successfully saved",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
}
