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
        static let todayRowHeight = 75.0
        static let todaySectionHeight = 22.0
        
        struct CellIdentifiers {
            static let content = "busViewCell"
            static let message = "messageCell"
        }
    }
    struct FavoriteRouteStop {
        var stopId: String;
        var routeId: String;
    }

    let locationManager = CLLocationManager()
    var favoriteList: Array<SwiftyJSON.JSON> = []{
        didSet {
            self.tableView.reloadData()
            resetContentSize()
        }
    }
    var favoriteDirectionList = Array<SwiftyJSON.JSON>()
    var routeList : Array<SwiftyJSON.JSON> = []{
        didSet {
                self.tableView.reloadData()
                resetContentSize()
        }
    }
    var routeDirectionList = Array<SwiftyJSON.JSON>()
    var networkError: Bool = false
    
    // MARK: View Sizing
    
    var preferredViewHeight: CGFloat { // this is so primitive. There must be a better way
        let itemCount = routeList.count > 0 && favoriteList.count > 0 ? favoriteList.count + routeList.count : 1
        let sectionHeaderCount = routeList.count > 0 ? 1 : 0 + favoriteList.count > 0 ? 1 : 0
        //let rowCount = showingAll ? itemCount : min(itemCount, TableViewConstants.baseRowCount + 1)
        
        return CGFloat(Double(itemCount) * TableViewConstants.todayRowHeight + Double(sectionHeaderCount) * TableViewConstants.todaySectionHeight)
    }
    
    func resetContentSize() {
        var preferredSize = preferredContentSize
        
        preferredSize.height = preferredViewHeight
        
        preferredContentSize = preferredSize
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
               //init location manager delegate and request A8uthoriization from user
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = true
        
        //use SharedDefaults to build the Favorite Stop Routes to display
        let sharedDefaults = NSUserDefaults(suiteName: "group.Musait-Yerde")
        
        //favStopId = sharedDefaults!.objectForKey("numberPass") as String
        //sharedDefaults.
        var favStopId: String = "1_13460"
        var favRouteId: String = "40_100236"
        let now = NSDate()
        //two ways to determine if its AM or PM
        //Method One: extract hour as integer using NSDateComponents
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components (NSCalendarUnit.CalendarUnitHour, fromDate: now)
        let hour = components.hour
        if hour < 12 { // Morning
            var favoriteStop_AM = FavoriteRouteStop(stopId: favStopId,routeId: favRouteId)
            updateFavStop([favoriteStop_AM])
        } else {
            //var favoriteStop_PM
            updateFavStop([FavoriteRouteStop(stopId: "1_71335",routeId: "40_100236"),FavoriteRouteStop(stopId: "1_71335",routeId: "40_100511"),FavoriteRouteStop(stopId: "1_10914",routeId: "1_100447")])
        }
        //Method Two: Build an string using NSDateFormatter and compare that against "AM"
        //Should be slower. But i need to bench first
        /*
        let aFormatter = NSDateFormatter()
        aFormatter.dateFormat = "a"
        if aFormatter.stringFromDate(now) == "AM" {
            
        } else {
        
        }
        */
        locationManager.startUpdatingLocation()
        
        
    }
    
    func updateFavStop(favoriteRouteStops: Array<FavoriteRouteStop>) {
        for favoriteRouteStop in favoriteRouteStops {

        Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(favoriteRouteStop.stopId).json?key=org.onebusaway.iphone&version=2")
            .responseJSON { (_, _, data, error) in
                var responseJSON: SwiftyJSON.JSON
                if error != nil {
                    self.networkError = true
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
                    var onFavRoute: Bool = $0["routeId"].stringValue == favoriteRouteStop.routeId;
                    println ("\(didntArriveYet && onFavRoute)");
                    return didntArriveYet && onFavRoute })
                favstop_buses.sort({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                if favstop_buses.count > 0 {
                    //Build the RouteNum by combining Bus Number and Bus Compass direction)
                    self.favoriteList.append(favstop_buses[0])
                    let busDirection = responseJSON["data"]["references"]["stops"][0]["direction"]
                    self.favoriteDirectionList.append(busDirection)

                }
            
        }
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top, left: 27.0, bottom: 0.0
            , right: defaultMarginInsets.right)
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
        println("\(latValue)")
        println("\(lonValue)")
        
        Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=org.onebusaway.iphone&app_uid=1EC3E57A-B013-40CC-A495-4F0A3CB2FC79&app_ver=2.2.1&lat=\(latValue)&lon=\(lonValue)&latSpan=0.002960&lonSpan=0.004426&version=2")
            .responseJSON { (_, _, data, error) in
                var responseJSON: SwiftyJSON.JSON
                if error != nil {
                    self.networkError = true;
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
                                
                                self.networkError = true;
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
                                
                            }
                    }
                            //println("\(stop1_id)")
                            Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop1_id).json?key=org.onebusaway.iphone&version=2")
                                .responseJSON { (_, _, data, error) in
                                    var responseJSON: SwiftyJSON.JSON
                                    if error != nil {
                                        
                                        self.networkError = true;
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

                    
                    }
                case 1:
                    
                    //println("Case 1")
                    let stop0_id: SwiftyJSON.JSON = stops[0]["id"]
                    //println("\(stop0_id)")
                    Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop0_id).json?key=org.onebusaway.iphone&version=2")
                        .responseJSON { (_, _, data, error) in
                            var responseJSON: SwiftyJSON.JSON
                            if error != nil {
                                
                                self.networkError = true;
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
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: //nearby Routes
            if routeList.count > 0  {
                return NSLocalizedString("Nearby Routes", comment: "")
            }
            else {
                return ""
            }
        case 0: //nearby Favorites
            if favoriteList.count > 0 {
                return NSLocalizedString("Favorite Routes", comment: "")
            }
            else {
                return ""
            }
        default:
            return ""
        }
    }
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
        var header = view as UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor.whiteColor()
        header.textLabel.font = UIFont(name: "Helventica Neue", size: 11)
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1: //nearby Routes
            if routeList.count < 1 {
                return 1
            }
            return min(routeList.count, TableViewConstants.baseRowCount + 1)
        case 0: //favorite Routes
            return favoriteList.count
        default:
            return 0
        }
    }

    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if routeList.count  > 0 || (favoriteList.count > 0 && indexPath.section == 0){
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as busViewCell
            if indexPath.section == 1 {
                configureBusItemCell(cell, busJSON: routeList[indexPath.row], busDirection: routeDirectionList[indexPath.row])
                tableView.headerViewForSection(indexPath.section)?.textLabel.text = "Nearby Routes"
            }
            else {
                configureBusItemCell(cell, busJSON: favoriteList[indexPath.row], busDirection: favoriteDirectionList[indexPath.row])
                tableView.headerViewForSection(indexPath.section)?.textLabel.text = "Favorite Route"
            }
            cell.textLabel.text = ""
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as UITableViewCell
            if networkError {
                cell.textLabel.text = NSLocalizedString("Network Error", comment: "")
            }
            else{
                cell.textLabel.text = NSLocalizedString("No Nearby buses and running Favorites.", comment: "")
            }
            cell.textLabel.textColor = UIColor.lightTextColor()
            return cell
        }
    }
    
    func configureBusItemCell(itemCell: busViewCell, busJSON: SwiftyJSON.JSON, busDirection: SwiftyJSON.JSON) {
        let busNum = busJSON["routeShortName"]
        let busHeadsign = busJSON["tripHeadsign"]
        
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
        itemCell.Destination.text = "\(busHeadsign)"
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
