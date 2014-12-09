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

class TodayViewController: UITableViewController, CLLocationManagerDelegate, NCWidgetProviding {

    
    struct TableViewConstants {
        static let baseRowCount = 3
        static let todayRowHeight = 75
        
        struct CellIdentifiers {
            static let content = "busViewCell"
            static let message = "messageCell"
        }
    }
    
    
    let locationManager = CLLocationManager()
    var favoriteList = Array<SwiftyJSON.JSON>()
    var favoriteDirectionList = Array<SwiftyJSON.JSON>()
    var routeList = Array<SwiftyJSON.JSON>()
    var routeDirectionList = Array<SwiftyJSON.JSON>()
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init location manager delegate and request A8uthoriization from user
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = true
        let sharedDefaults = NSUserDefaults(suiteName: "group.Musait-Yerde")
        var favStopId: String = "1_13460"
        //favStopId = sharedDefaults!.objectForKey("numberPass") as String
        //sharedDefaults.
        
        println(favStopId)
        
        updateFavStop(favStopId,favRouteId: "40_100236")

        
        locationManager.startUpdatingLocation()
        
    }
    
    func updateFavStop(favStopId: String , favRouteId: String) {
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
                var favstop_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                //println("\(favstop_buses)")
                
                let currentTime: Int = responseJSON["currentTime"].intValue
                
                favstop_buses = favstop_buses.filter({
                    var didntArriveYet: Bool = $0["predictedArrivalTime"].intValue > currentTime;
                    var onFavRoute: Bool = $0["routeId"].stringValue == favRouteId;
                    println ("\(didntArriveYet && onFavRoute)");
                    return didntArriveYet && onFavRoute })
                favstop_buses.sort({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                if favstop_buses.count > 0 {
                    //Build the RouteNum by combining Bus Number and Bus Compass direction)
                    self.favoriteList.append(favstop_buses[0])
                    let busNum = favstop_buses[0]["routeShortName"]
                    let busDirection = responseJSON["data"]["references"]["stops"][0]["direction"]
                    self.favoriteDirectionList.append(busDirection)
                }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top, left: 27.0, bottom: defaultMarginInsets.bottom, right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        //TODO~~this grabs the Favorite Bus route from the Parent App~~
        
        
        
        
        
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.NewData)
    }
    // MARK: CLLocationManagerDelegate
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        
        //stop polling for locations after first time (don't expect hte user to move particularly far before closing the today widget) TODO
        locationManager.stopUpdatingLocation()

        
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
                
                println("stops count = \(stops.count)")
                switch stops.count {
                case 2...Int.max:
                    //println("Case 2")
                    let stop0_id: SwiftyJSON.JSON = stops[0]["id"]
                    let stop1_id: SwiftyJSON.JSON = stops[1]["id"]

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
                            let currentTime: Int = responseJSON["currentTime"].intValue

                            stop0_buses = stop0_buses.filter({
                                $0["predictedArrivalTime"].intValue > currentTime})
                            stop0_buses.sort({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                            
                            //println("\(stop0_buses)")
                            if stop0_buses.count > 0 {
                                //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                let busNum = stop0_buses[0]["routeShortName"]

                                let busDirection = stops[0]["direction"]
                                self.routeList.append(stop0_buses[0])
                                self.routeDirectionList.append(busDirection)
                                println("C2S0 RouteList count: \(self.routeList.count)")
                                self.tableView.reloadData()
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
                                    var stop1_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                                    let currentTime: Int = responseJSON["currentTime"].intValue

                                    stop1_buses = stop1_buses.filter({
                                        $0["predictedArrivalTime"].intValue > currentTime})
                                    stop1_buses.sort({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})

                                    if stop1_buses.count > 0 {
                                        //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                        let busNum = stop1_buses[0]["routeShortName"]
                                        let busDirection = stops[1]["direction"]
                                        
                                        
                                        self.routeList.append(stop1_buses[0])
                                        self.routeDirectionList.append(busDirection)
                                        
                                        println("C2S1 RouteList count: \(self.routeList.count)")
                                    }
                                    
                                    self.tableView.reloadData()

                    
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
                            
                            let currentTime: Int = responseJSON["currentTime"].intValue

                            stop0_buses = stop0_buses.filter({
                                $0["predictedArrivalTime"].intValue > currentTime})
                            stop0_buses.sort({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                            
                            if stop0_buses.count > 0 {
                                //we pick the first bus that is predicted to arrive AFTER current time
                                var i: Int = 0
                                var i_arrival: Int = stop0_buses[i]["predictedArrivalTime"].intValue
                                while  i_arrival < currentTime {
                                    i = i+1
                                    if i == stop0_buses.count {
                                        return
                                    }
                                    i_arrival = stop0_buses[i]["predictedArrivalTime"].intValue
                                }
                            
                                //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                let busNum = stop0_buses[0]["routeShortName"]
                                let busDirection = stops[0]["direction"]
                                self.routeList.append(stop0_buses[0])
                                self.routeDirectionList.append(busDirection)
                                println("C1B0 RouteList count: \(self.routeList.count)")
                                if stop0_buses.count > 1
                                {
                                //Build the RouteNum by combining Bus Number and Bus Compass direction)
                                let bus2Num = stop0_buses[1]["routeShortName"]
                                self.routeList.append(stop0_buses[1])
                                self.routeDirectionList.append(busDirection)
                                println("C1B1 RouteList count: \(self.routeList.count)")
                                }
                                
                                //self.tableView.reloadData()
                            }
                    }
                case 0:
                    println("Case 0")
                default:
                    
                    println("Case Default")
                }
                
                
                
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 2
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            if routeList.count < 1 {
                return 1
            }
            return min(routeList.count, TableViewConstants.baseRowCount + 1)
        case 0:
            return favoriteList.count
        default:
            return 0
        }
    }

    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if routeList.count > 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as busViewCell
            if indexPath.section == 1 {
                configureBusItemCell(cell, busJSON: routeList[indexPath.row], busDirection: routeDirectionList[indexPath.row])
                tableView.headerViewForSection(indexPath.section)?.textLabel.text = "Nearby Routes"
            }
            else {
                configureBusItemCell(cell, busJSON: favoriteList[indexPath.row], busDirection: favoriteDirectionList[indexPath.row])
                tableView.headerViewForSection(indexPath.section)?.textLabel.text = "Favorite Route"
            }

            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as UITableViewCell
                cell.textLabel.text = NSLocalizedString("No items in today's list", comment: "")

            return cell
        }
    }
    
    func configureBusItemCell(itemCell: busViewCell, busJSON: SwiftyJSON.JSON, busDirection: SwiftyJSON.JSON) {
        let busNum = busJSON["routeShortName"]
        
        itemCell.RouteNum.text = "\(busNum)\(busDirection)"
        
        //Json provides epoch time in milliseconds were converting to seconds.
        let busPredictedArrivalEpochTime = busJSON["predictedArrivalTime"].doubleValue/1000
        let now = NSDate()
        
        //Display Minutes to bus arrival
        //I could use NSDate to compare now and arrival, i shoudldo that maybe?
        //this works for now TODO
        itemCell.Minutes.text = String(Int((busPredictedArrivalEpochTime - now.timeIntervalSince1970)/60))
        
        //Display arrival time in 12:00 AM format
        let arrival = NSDate(timeIntervalSince1970: busPredictedArrivalEpochTime)
        let hhmmFormatter = NSDateFormatter()
        hhmmFormatter.dateFormat = "h:mm a"
        itemCell.ArrivalTime.text = hhmmFormatter.stringFromDate(arrival)
    }
    
    
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            tableView.reloadData()
        /*
            tableView.beginUpdates()
            let indexPathForRemoval = NSIndexPath(forRow: 0, inSection: 0)
            tableView.deleteRowsAtIndexPaths([indexPathForRemoval], withRowAnimation: .Fade)
        
        
        
            let insertedIndexPathRange = 0..<routeList.count
            var insertedIndexPaths = insertedIndexPathRange.map { NSIndexPath(forRow: $0, inSection: 0) }
        
        
        
        tableView.insertRowsAtIndexPaths(insertedIndexPaths, withRowAnimation: .Fade)
            tableView.endUpdates()
            */
        
    
    }
    
    

    
}
