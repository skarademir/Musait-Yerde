//
//  TodayViewController.swift
//  GeliyorGidiyor
//
//  Created by Saruhan on 5-10-14.
//  Copyright (c) 2014 KaraBal. All rights reserved.
//

import UIKit
import Alamofire
import NotificationCenter
import CoreLocation
import SwiftyJSON


class TodayViewController: UIViewController, CLLocationManagerDelegate, NCWidgetProviding {
    @IBOutlet var NearbyOne_RouteNum: UILabel!
    @IBOutlet var NearbyOne_Minutes: UILabel!
    @IBOutlet var NearbyOne_ArrivalTime: UILabel!
    
    @IBOutlet var NearbyTwo_RouteNum: UILabel!
    @IBOutlet var NearbyTwo_Minutes: UILabel!
    @IBOutlet var NearbyTwo_ArrivalTime: UILabel!
    
    @IBOutlet var Fav_RouteNum: UILabel!
    @IBOutlet var Fav_Minutes: UILabel!
    @IBOutlet var Fav_ArrivalTime: UILabel!
    
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init location manager delegate and request A8uthoriization from user
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.startUpdatingLocation()
        
    }
    func updateFavStop(favStopId: String ) {
        Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(favStopId).json?key=org.onebusaway.iphone&version=2")
            .responseJSON { (_, _, data, error) in
                var responseJSON: SwiftyJSON.JSON
                if error != nil {
                    responseJSON = SwiftyJSON.JSON.nullJSON
                } else if data != nil {
                    responseJSON = SwiftyJSON.JSON(data!)
                } else {
                    responseJSON = SwiftyJSON.JSON.nullJSON
                }
                //println("\(responseJSON)")
                let favstop_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                //println("\(favstop_buses)")
                if favstop_buses.count > 0 {
                    //we pick the first bus that is predicted to arrive AFTER current time
                    //yes this is ghetto TODO
                    var i: Int = 0
                    let currentTime: Int = responseJSON["currentTime"].intValue
                    var i_arrival: Int = favstop_buses[i]["predictedArrivalTime"].intValue
                    while  i_arrival < currentTime {
                        i = i+1
                        if i == favstop_buses.count {
                            return
                        }
                        i_arrival = favstop_buses[i]["predictedArrivalTime"].intValue
                    }
                    
                    
                    //Build the RouteNum by combining Bus Number and Bus Compass direction)
                    let busNum = favstop_buses[i]["routeShortName"]
                    let busDirection = responseJSON["data"]["references"]["stops"][0]["direction"]
                    self.Fav_RouteNum.text = "\(busNum)\(busDirection)"
                    
                    //Json provides epoch time in milliseconds were converting to seconds.
                    let busPredictedArrivalEpochTime = favstop_buses[i]["predictedArrivalTime"].doubleValue/1000
                    let now = NSDate()
                    
                    //Display Minutes to bus arrival
                    //I could use NSDate to compare now and arrival, i shoudldo that maybe?
                    //this works for now TODO
                    self.Fav_Minutes.text = String(Int((busPredictedArrivalEpochTime - now.timeIntervalSince1970)/60))
                    
                    //Display arrival time in 12:00 AM format
                    let arrival = NSDate(timeIntervalSince1970: busPredictedArrivalEpochTime)
                    let hhmmFormatter = NSDateFormatter()
                    hhmmFormatter.dateFormat = "h:mm a"
                    self.Fav_ArrivalTime.text = hhmmFormatter.stringFromDate(arrival)
                }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        updateFavStop("1_13460")
        //TODO~~this grabs the Favorite Bus route from the Parent App~~
        //let sharedDefaults = NSUserDefaults(suiteName: “group.YOURGROUPHERE”)
        
        //favRouteNum.text = sharedDefaults.objectForKey(“numberPass”) as String
        
        
        
        
        
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.NewData)
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        //test if authorization was given, if so try to determine Nearby Routes
        
        
        //println("locations = \(locations)")
        var latValue = locationManager.location.coordinate.latitude
        var lonValue = locationManager.location.coordinate.longitude
        //println("\(latValue)")
        //println("\(lonValue)")
        
        Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=org.onebusaway.iphone&app_uid=1EC3E57A-B013-40CC-A495-4F0A3CB2FC79&app_ver=2.2.1&lat=\(latValue)&lon=\(lonValue)&latSpan=0.002960&lonSpan=0.004426&version=2")
            .responseJSON { (_, _, data, error) in
                var responseJSON: SwiftyJSON.JSON
                if error != nil {
                    responseJSON = SwiftyJSON.JSON.nullJSON
                    //println("nullJSON")
                    //println("\(error)")
                } else if data != nil {
                    responseJSON = SwiftyJSON.JSON(data!)
                    //println("JSON")
                } else {
                    responseJSON = SwiftyJSON.JSON.nullJSON
                    //println("nullJSONelse")
                }
                
                //println("\(responseJSON)")
                
                let stops: Array<JSON> = responseJSON["data"]["list"].arrayValue
                
                //println("stops count = \(stops.count)")
                switch stops.count {
                case 2...Int.max:
                    //println("Case 2")
                    let stop0_id: SwiftyJSON.JSON = stops[0]["id"]
                    let stop1_id: SwiftyJSON.JSON = stops[1]["id"]
                    //println("\(stop0_id)")
                    Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop0_id).json?key=org.onebusaway.iphone&version=2")
                        .responseJSON { (_, _, data, error) in
                            var responseJSON: SwiftyJSON.JSON
                            if error != nil {
                                responseJSON = SwiftyJSON.JSON.nullJSON
                            } else if data != nil {
                                responseJSON = SwiftyJSON.JSON(data!)
                            } else {
                                responseJSON = SwiftyJSON.JSON.nullJSON
                            }
                            //println("\(responseJSON)")
                            let stop0_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                            if stop0_buses.count > 0 {
                                //we pick the first bus that is predicted to arrive AFTER current time
                                //yes this is ghetto TODO
                                var i: Int = 0
                                let currentTime: Int = responseJSON["currentTime"].intValue
                                var i_arrival: Int = stop0_buses[i]["predictedArrivalTime"].intValue
                                while  i_arrival < currentTime {
                                    i = i+1
                                    if i == stop0_buses.count {
                                        return
                                    }
                                    i_arrival = stop0_buses[i]["predictedArrivalTime"].intValue
                                }
                                
                                
                                //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                let busNum = stop0_buses[i]["routeShortName"]
                                let busDirection = stops[i]["direction"]
                                self.NearbyOne_RouteNum.text = "\(busNum)\(busDirection)"
                                
                                //Json provides epoch time in milliseconds were converting to seconds.
                                let busPredictedArrivalEpochTime = stop0_buses[i]["predictedArrivalTime"].doubleValue/1000
                                let now = NSDate()
                                
                                //Display Minutes to bus arrival
                                //I could use NSDate to compare now and arrival, i shoudldo that maybe?
                                //this works for now TODO
                                self.NearbyOne_Minutes.text = String(Int((busPredictedArrivalEpochTime - now.timeIntervalSince1970)/60))
                                
                                //Display arrival time in 12:00 AM format
                                let arrival = NSDate(timeIntervalSince1970: busPredictedArrivalEpochTime)
                                let hhmmFormatter = NSDateFormatter()
                                hhmmFormatter.dateFormat = "h:mm a"
                                self.NearbyOne_ArrivalTime.text = hhmmFormatter.stringFromDate(arrival)
                            }
                    }
                            //println("\(stop1_id)")
                            Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop1_id).json?key=org.onebusaway.iphone&version=2")
                                .responseJSON { (_, _, data, error) in
                                    var responseJSON: SwiftyJSON.JSON
                                    if error != nil {
                                        responseJSON = SwiftyJSON.JSON.nullJSON
                                    } else if data != nil {
                                        responseJSON = SwiftyJSON.JSON(data!)
                                    } else {
                                        responseJSON = SwiftyJSON.JSON.nullJSON
                                    }
                                    //println("\(responseJSON)")
                                    let stop1_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                                    if stop1_buses.count > 0 {
                                        //we pick the first bus that is predicted to arrive AFTER current time
                                        //yes this is ghetto TODO
                                        var i: Int = 0
                                        let currentTime: Int = responseJSON["currentTime"].intValue
                                        var i_arrival: Int = stop1_buses[i]["predictedArrivalTime"].intValue
                                        while  i_arrival < currentTime {
                                            i = i+1
                                            if i == stop1_buses.count {
                                                return
                                            }
                                            i_arrival = stop1_buses[i]["predictedArrivalTime"].intValue
                                        }
                                        
                                        
                                        //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                        let busNum = stop1_buses[i]["routeShortName"]
                                        let busDirection = stops[i]["direction"]
                                        self.NearbyTwo_RouteNum.text = "\(busNum)\(busDirection)"
                                        
                                        //Json provides epoch time in milliseconds were converting to seconds.
                                        let busPredictedArrivalEpochTime = stop1_buses[i]["predictedArrivalTime"].doubleValue/1000
                                        let now = NSDate()
                                        
                                        //Display Minutes to bus arrival
                                        //I could use NSDate to compare now and arrival, i shoudldo that maybe?
                                        //this works for now TODO
                                        self.NearbyTwo_Minutes.text = String(Int((busPredictedArrivalEpochTime - now.timeIntervalSince1970)/60))
                                        
                                        //Display arrival time in 12:00 AM format
                                        let arrival = NSDate(timeIntervalSince1970: busPredictedArrivalEpochTime)
                                        let hhmmFormatter = NSDateFormatter()
                                        hhmmFormatter.dateFormat = "h:mm a"
                                        self.NearbyTwo_ArrivalTime.text = hhmmFormatter.stringFromDate(arrival)
                                    }

                    
                    }
                case 1:
                    
                    //println("Case 1")
                    let stop0_id: SwiftyJSON.JSON = stops[0]["id"]
                    //println("\(stop0_id)")
                    Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop0_id).json?key=org.onebusaway.iphone&version=2")
                        .responseJSON { (_, _, data, error) in
                            var responseJSON: SwiftyJSON.JSON
                            if error != nil {
                                responseJSON = SwiftyJSON.JSON.nullJSON
                            } else if data != nil {
                                responseJSON = SwiftyJSON.JSON(data!)
                            } else {
                                responseJSON = SwiftyJSON.JSON.nullJSON
                            }
                            //println("\(responseJSON)")
                            var stop0_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                            switch stop0_buses.count {
                            case 1...Int.max:
                                //we pick the first bus that is predicted to arrive AFTER current time
                                //yes this is ghetto TODO
                                var i: Int = 0
                                let currentTime: Int = responseJSON["currentTime"].intValue
                                var i_arrival: Int = stop0_buses[i]["predictedArrivalTime"].intValue
                                while  i_arrival < currentTime {
                                    i = i+1
                                    if i == stop0_buses.count {
                                        return
                                    }
                                    i_arrival = stop0_buses[i]["predictedArrivalTime"].intValue
                                }
                            
                                //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                let busNum = stop0_buses[i]["routeShortName"]
                                let busDirection = stops[i]["direction"]
                                self.NearbyOne_RouteNum.text = "\(busNum)\(busDirection)"
                                
                                //Json provides epoch time in milliseconds were converting to seconds.
                                let busPredictedArrivalEpochTime = stop0_buses[i]["predictedArrivalTime"].doubleValue/1000
                                let now = NSDate()
                                
                                //Display Minutes to bus arrival
                                //I could use NSDate to compare now and arrival, i shoudldo that maybe?
                                //this works for now TODO
                                self.NearbyOne_Minutes.text = String(Int((busPredictedArrivalEpochTime - now.timeIntervalSince1970)/60))
                                
                                //Display arrival time in 12:00 AM format
                                let arrival = NSDate(timeIntervalSince1970: busPredictedArrivalEpochTime)
                                let hhmmFormatter = NSDateFormatter()
                                hhmmFormatter.dateFormat = "h:mm a"
                                self.NearbyOne_ArrivalTime.text = hhmmFormatter.stringFromDate(arrival)
                                //TODO oh god im so sorry this is the worst
                                stop0_buses.removeAtIndex(i)
                                
                                i = 0
                                i_arrival = stop0_buses[i]["predictedArrivalTime"].intValue
                                while  i_arrival < currentTime {
                                    i = i+1
                                    if i == stop0_buses.count {
                                        return
                                    }
                                    i_arrival = stop0_buses[i]["predictedArrivalTime"].intValue
                                }
                                
                                //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                let bus2Num = stop0_buses[i]["routeShortName"]
                                let bus2Direction = stops[i]["direction"]
                                self.NearbyTwo_RouteNum.text = "\(busNum)\(busDirection)"
                                
                                //Json provides epoch time in milliseconds were converting to seconds.
                                let bus2PredictedArrivalEpochTime = stop0_buses[i]["predictedArrivalTime"].doubleValue/1000
                                
                                
                                //Display Minutes to bus arrival
                                //I could use NSDate to compare now and arrival, i shoudldo that maybe?
                                //this works for now TODO
                                self.NearbyTwo_Minutes.text = String(Int((busPredictedArrivalEpochTime - now.timeIntervalSince1970)/60))
                                
                                //Display arrival time in 12:00 AM format
                                let arrival2 = NSDate(timeIntervalSince1970: busPredictedArrivalEpochTime)
                                self.NearbyTwo_ArrivalTime.text = hhmmFormatter.stringFromDate(arrival)
                            case 0:
                                println("Case 0")
                            default:
                                println("Case Default")
                            }
                    }
                case 0:
                    println("Case 0")
                default:
                    println("Case Default")
                }
                
                
                
        }
        //stop polling for locations after first time (don't expect hte user to move particularly far before closing the today widget) TODO
        locationManager.stopUpdatingLocation()
        
        
    }
    
}
