//
//  StepHistoryController.swift
//  NYU Mobility 3
//
//  Created by Jin Kim on 3/3/21.
//

import UIKit
import HealthKit
import QuartzCore

class StepHistoryController: UIViewController, LineChartDelegate {
    
    let healthStore = HKHealthStore()
    var stepHistory: [CGFloat] = []
    
    var label = UILabel()
    var lineChart: LineChart!
    
    // Future: Add labels for averages for the last week
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        getHealthKitPermission() { res in
            DispatchQueue.main.async {
                // Can only alter the chart in the main thread
                // as it relies on views + label
                self.addChart(res)
                
                // A function to use res to find the averages
            }
        }
    }
    
    func addChart(_ val: [CGFloat]) {
        var views: [String: AnyObject] = [:]
        
        label.text = "..."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = NSTextAlignment.center
        self.view.addSubview(label)
        views["label"] = label
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[label]", options: [], metrics: nil, views: views))
        
        var data: [CGFloat] = []
        
        for index in 0 ..< val.count - 1 {
            data.append(val[index])
        }
        
        data.reverse()
        
        let _ = data.popLast()
        
        let xLabel = Date.getDates(forLastNDays: 7)
        
        print(data)
        print(xLabel)
        
        lineChart = LineChart()
        lineChart.animation.enabled = true
        lineChart.area = true
        lineChart.x.labels.visible = true
        
        // If for whatever reason, the x labels do not match the y label points
        // Simply skip the x labels
        if (xLabel.count == data.count) {
            lineChart.x.labels.values = xLabel
        }
        
        lineChart.x.grid.count = 5
        lineChart.y.grid.count = 5
        lineChart.y.labels.visible = false
        lineChart.addLine(data)
        
        lineChart.translatesAutoresizingMaskIntoConstraints = false
        lineChart.delegate = self
        self.view.addSubview(lineChart)
        views["chart"] = lineChart
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[chart]-|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[label]-5-[chart(==200)]", options: [], metrics: nil, views: views))
        
    }
    
    func getHealthKitPermission(completion: @escaping ([CGFloat]) -> Void) {

        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        let stepsCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!

        self.healthStore.requestAuthorization(toShare: [], read: [stepsCount]) { (success, error) in
            if success {
//                print("Permission accepted.")
                self.getTodaySteps() { res in
                    completion(res)
                }
            }
            else {
                if error != nil {
                    print(error ?? "")
                }
//                print("Permission denied.")
            }
        }
    }
    
    func getTodaySteps(completion: @escaping ([CGFloat]) -> Void) {
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
                    self.stepHistory.append(CGFloat(totalForDay))
                }
            )
            completion(self.stepHistory)
        }
        healthStore.execute(query)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func didSelectDataPoint(_ x: CGFloat, yValues: [CGFloat]) {
        // Precondition - There are no negative values
        let steps: Int = Int(yValues[0])
        label.textColor = UIColor.black
        
        // Number of steps for the label
        if (steps != 1) {
            label.text = "\(steps) steps"
        } else {
            label.text = "\(steps) step"
        }
    }
    
    // Redraw chart on device rotation
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if let chart = lineChart {
            chart.setNeedsDisplay()
        }
    }
}

// Used for x labels for each date
extension Date {
    static func getDates(forLastNDays nDays: Int) -> [String] {
        let cal = NSCalendar.current
        // Start with today
        var date = cal.startOfDay(for: Date())

        var arrDates = [String]()

        for _ in 1 ... nDays {
            // Move back in time by one day:
            date = cal.date(byAdding: Calendar.Component.day, value: -1, to: date)!

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd"
            let dateString = dateFormatter.string(from: date)
            arrDates.append(dateString)
        }
        return arrDates
    }
}
