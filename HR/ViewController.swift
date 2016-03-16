//
//  ViewController.swift
//  HR
//
//  Created by Karan Thukral on 2016-03-15.
//  Copyright © 2016 Karan Thukral. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity
import Starscream

class ViewController: UIViewController, WCSessionDelegate, WebSocketDelegate {

    @IBOutlet weak var hrLabel: UILabel!
    
    let healthStore = HKHealthStore()
    let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    
    
    // define the activity type and location
    let heartRateUnit = HKUnit(fromString: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    var query: HKQuery?
    
    var session : WCSession!
    var socket: WebSocket!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        query = createHeartRateStreamingQuery(nil)
//        runHR()
//        healthStore.enableBackgroundDeliveryForType(quantityType!, frequency: HKUpdateFrequency.Immediate) { (did, error) -> Void in
//            print(error)
//        }
        // Do any additional setup after loading the view, typically from a nib.
        //NSTimer.scheduledTimerWithTimeInterval(15.0, target: self, selector: Selector("runHR"), userInfo: nil, repeats: true)

        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self;
            session.activateSession()
        }
        
        socket = WebSocket(url: NSURL(string: "ws://design-ws-demo.herokuapp.com")!)
        socket.delegate = self
        socket.connect()
        
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("websocket is disconnected: \(error?.localizedDescription)")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("got some text: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("got some data: \(data.length)")
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("got something")
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        let heartRate = message["hr"] as! String
        print("got something: " + heartRate)
        dispatch_async(dispatch_get_main_queue()) {
            self.hrLabel.text = heartRate
            let str = "{\"handle\": \"iOS\", \"hr\": \"\(heartRate)\"}"
            self.socket.writeString(str)
        }
    }
    
    func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
        print("got something")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func runHR() {
        healthStore.executeQuery(query!)
    }
    
    func createHeartRateStreamingQuery(workoutStartDate: NSDate?) -> HKQuery? {
        // adding predicate will not work
        // let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType!, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else {return}
            self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(samples: [HKSample]?) {
        healthStore.stopQuery(query!)
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        dispatch_async(dispatch_get_main_queue()) {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
            self.hrLabel.text = String(UInt16(value))
        }
    }



}

