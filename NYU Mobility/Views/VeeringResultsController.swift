//
//  VeeringResultsController.swift
//  NYU Mobility
//
//  Created by Jin Kim on 5/5/21.
//

import UIKit

// Used to determine what direction the veering was done
enum Direction {
    case left
    case right
    case straight
}

/// After the veering session is completed -> The app will redirect to this screen for the user to see the results
/// We are placing this here now because the session tracking screen will have one giant button
class VeeringResultsController: UIViewController {
    
    @IBOutlet weak var sessionLabel: UILabel!
    @IBOutlet weak var veeringLabel: UILabel!
    
    @IBOutlet weak var veeringModel: UIView!
    
    // Veering in a particular direction
    var distance: Int = 0
    
    //
    // All of the data below is not created here but passed into the
    // view from DebugController.swift where the data is collected
    // through the location manager
    //
    
    // Used as a method of regularization when the graphic is drawn
    // (to ensure that it fits into the frame)
    var totalTime: Int = 0
    // Used to store the history of each interval to draw out
    var timeIntervals: [Int] = []
    // Orientation Array
    var compassTrackings: [Double] = []
    
    //
    // Constants used to draw the graphic
    //
    
    // CONSTANT for how wide the veering should be - this should not be too high
    // to avoid clipping
    let X_MOVE: Double = 25.0
    
    // CONSTANT for how tall the veering height should be - this should also not be too high
    // to avoid clipping
    let Y_MOVE: Double = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calculateVeering()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true) // animates view disappearing
        clearVeeringModel()
    }
    
    /**
     After the session is completed: the calculations are made and veering is detected (either in left and right)
     Finally, the draw veering model function is called -> which will draw out the graphic for the actual veering
     */
    func calculateVeering() {
        
        // Edge cases
        // No calculations to make if session was too short or perfect
        if (compassTrackings.count == 0) {
            veeringLabel.text = "Session was too short to detect veering"
            return
        // If there is only one compass entry -> There was no veering
        // Or the session was too short
        } else if (compassTrackings.count == 1) {
            veeringLabel.text = "No veering was detected in this session"
            return
        }
        
        // Left and right derivative counters
        // We increment these counters for each left + right movement
        // The overall count of these counters will determine whether
        // veering was to the left or to the right
        var lC: Int = 0, rC: Int = 0
        var prev: Double = compassTrackings.first!, curr: Double = 0.0
        
        for i in 1 ..< compassTrackings.count {
            curr = compassTrackings[i]
            // Crossing North threshold (l -> r)
            if (prev >= 0 && prev < 5 && curr > 355) {
                lC += 1
            // Crossing (r -> l)
            } else if (prev > 355 && curr >= 0 && curr < 5) {
                rC += 1
            } else if (curr > prev) {
                rC += 1
            } else {
                lC += 1
            }
            prev = compassTrackings[i] // Update previous to be current after
        }
        
        // Can force unwrap since we are now guaranteed to have values:
        let startTheta = compassTrackings.first!
        let endTheta = compassTrackings.last!
        
        // Currently the way we detect the difference in theta (veering angle)
        // Takes the minimum of difference -> as the theta of degrees
        let dTheta = min(abs(startTheta - endTheta), abs(360 - startTheta + endTheta))
        let estVeer = abs(sin(dTheta) * Double(distance))
        
        veeringLabel.text = "Estimated Veering: \(estVeer.truncate(places: 2)) m, dTheta: \(dTheta.truncate(places: 2))°"
        
        // This indicates veering to the left - more left derivative values
        if (lC > rC) {
            drawVeeringModel(Direction.left)
        } else if (rC > lC) {
            drawVeeringModel(Direction.right)
        } else {
            // Overall no veering detected (net zero)
            drawVeeringModel(Direction.straight)
        }
    }
    
    /**
     The actual function that draws out the veering once the direction is determined in stopTracking()
     There are two cases (in the current build):
        - Left -> Red color triangle
        - Right -> Blue color triangle
     
     There are also a lot of visual calculations that are made using the arrays for orientation and time stamps
     */
    func drawVeeringModel(_ direction: Direction) {
        let heightWidth = veeringModel.frame.size.width
        let path = CGMutablePath()
        
        let hLen: Int = compassTrackings.count
        let changeY: Double = Double(heightWidth)
        var deltaY: Double = 0.0
        
        // Used to move the path a certain amount based on prior compass
        // trackings
        var newX: Double = Double(heightWidth) / 2.0
        var newY: Double = Double(heightWidth)
        
        var xChanges: [Double] = []
        var xTotal: Double = 0.0
        
        if (direction == .left) {
            path.move(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            // This is where the calculations are made
            for i in 1 ..< hLen {
                let deltaTheta: CGFloat = CGFloat(compassTrackings[i]) - CGFloat(compassTrackings[i - 1])
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                if (deltaTheta < 0) { // Going right
                    let c = Double((Double(deltaY) * Double(tan(abs(deltaTheta)))))
                    xTotal += c
                    xChanges.append(-c)
                } else { // Going left
                    let c = Double((Double(deltaY) * Double(tan(deltaTheta))))
                    xTotal += c
                    xChanges.append(c)
                }
            }
            
            // Where the path is actually drawn
            for i in 1 ..< xChanges.count {
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                newY -= deltaY
                newX += (xChanges[i] / xTotal) * X_MOVE
                path.addLine(to: CGPoint(x: newX, y: newY))
            }
            
            // This completes the triangle
            path.addLine(to: CGPoint(x: newX, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            let shape = CAShapeLayer()
            shape.path = path
            // Color that the triangle is filled in
            shape.fillColor = UIColor.red.cgColor
            
            veeringModel.layer.insertSublayer(shape, at: 0)
        } else if (direction == .right) {
            
            path.move(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            // This is where the calculations are made
            for i in 1 ..< hLen {
                let deltaTheta: CGFloat = CGFloat(compassTrackings[i]) - CGFloat(compassTrackings[i - 1])
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                
                if (deltaTheta < 0) { // Going right
                    let c = Double((Double(deltaY) * Double(tan(abs(deltaTheta)))))
                    xTotal += c
                    xChanges.append(c)
                } else { // Going left
                    let c = Double((Double(deltaY) * Double(tan(deltaTheta))))
                    xTotal += c
                    xChanges.append(c)
                }
            }
            
            // Where the path is actually drawn
            for i in 1 ..< xChanges.count {
                deltaY = (Double(timeIntervals[i]) / Double(totalTime)) * changeY * Y_MOVE
                newY -= deltaY
                newX += (xChanges[i] / xTotal) * X_MOVE
                path.addLine(to: CGPoint(x: newX, y: newY))
            }

            // This completes the triangle
            path.addLine(to: CGPoint(x: newX, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: 0))
            path.addLine(to: CGPoint(x: heightWidth / 2, y: heightWidth))
            
            let shape = CAShapeLayer()
            shape.path = path
            // Color that the triangle is filled in
            shape.fillColor = UIColor.blue.cgColor

            veeringModel.layer.insertSublayer(shape, at: 0)
        }
    }
    
    /**
     This function is used to clear the veering model and all of its corresponding variables
     This includes the compass trackings, time interval trackings, and the total time that is an
     accumulated sum
     
     Use this when leaving the screen to start a new session
     */
    func clearVeeringModel() {
        guard let sublayers = veeringModel.layer.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
        clearSessionData()
    }
    
    // Clears all the session data -> mainly used in clearVeeringModel()
    // Used as a safety measure, ideally the values would be overridden in the
    // prepare function
    func clearSessionData() {
        compassTrackings.removeAll() // Removes the previous session's trackers
        timeIntervals.removeAll() // Clears time slots
        totalTime = 0
        distance = 0
    }
}
