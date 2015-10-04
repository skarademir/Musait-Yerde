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
        static let maxRowCount = 7 //limits the total number of stops displayed
        static let todayRowHeight = 75.0
        static let todaySectionHeight = 43.0
        
        struct CellIdentifiers {
            static let content = "busViewCell"
        }
    }
    struct FavoriteRouteStop {
        var stopId: String;
        var routeId: String;
    }

    let locationManager = CLLocationManager()
    var sharedDefaults = NSUserDefaults(suiteName: "group.Musait-Yerde")
    
    var favoriteList: Array<SwiftyJSON.JSON> = []{
        didSet {
            self.tableView.reloadData()
            resetContentSize()
        }
    }
    var favoriteStopList = Array<SwiftyJSON.JSON>()
    
    var nearbyStopOneBusList : Array<SwiftyJSON.JSON> = []{
        didSet {
                self.tableView.reloadData()
                resetContentSize()
        }
    }
    var nearbyStopOneList: SwiftyJSON.JSON = SwiftyJSON.JSON.null;
    
    var nearbyStopTwoBusList : Array<SwiftyJSON.JSON> = []{
        didSet {
            self.tableView.reloadData()
            resetContentSize()
        }
    }
    var nearbyStopTwoList: SwiftyJSON.JSON = SwiftyJSON.JSON.null;
    
    var networkError: Bool = false
    
    // MARK: View Sizing
    
    var preferredViewHeight: CGFloat { // this is so primitive. There must be a better way
        let itemCount = (nearbyStopOneBusList.count > 0 || nearbyStopTwoBusList.count > 0) && favoriteList.count > 0 ? favoriteList.count + nearbyStopOneBusList.count + nearbyStopTwoBusList.count : 1
        let sectionHeaderCount = nearbyStopTwoBusList.count > 0 ? 1 : 0 + nearbyStopOneBusList.count > 0 ? 1 : 0 + favoriteList.count > 0 ? 1 : 0
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
        
        sharedDefaults?.synchronize()
        
               //init location manager delegate and request A8uthoriization from user
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = true
        var favoriteStop_PM  = [FavoriteRouteStop(stopId: "1_71335",routeId: "40_100236"),FavoriteRouteStop(stopId: "1_71335",routeId: "40_100511"),FavoriteRouteStop(stopId: "1_10914",routeId: "1_100447")]
        //use SharedDefaults to build the Favorite Stop Routes to display
//        if let SD_favStopId = sharedDefaults!.setObject(<#value: AnyObject?#>, forKey: <#String#>)("numberPass")
//        {
//            println(SD_favStopId)
//        }
        //sharedDefaults.
        var favStopId: String = "1_13460"
        var favRouteId: String = "40_100236"
        let now = NSDate()
        //two ways to determine if its AM or PM
        //Method One: extract hour as integer using NSDateComponents
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components (NSCalendarUnit.Hour, fromDate: now)
        let hour = components.hour //24h
        if hour < 12 { // Morning (any time before 12pm)
            var favoriteStop_AM = FavoriteRouteStop(stopId: favStopId,routeId: favRouteId)
            updateFavStop([favoriteStop_AM])
        } else { // Evening
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
            .responseJSON { response in
                var responseJSON: SwiftyJSON.JSON = SwiftyJSON.JSON.null

                switch response.result {
                case .Success:
                    print("Validation Successful")
                    if (response.result.value != nil) {
                        responseJSON = SwiftyJSON.JSON(response.result.value!)
                    }
                case .Failure(let error):
                    debugPrint(error)
                    self.networkError = true
                    return
                }
                
                var favstop_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                //println("\(favstop_buses)")
                
                let currentTime: Int = responseJSON["currentTime"].intValue
                
                favstop_buses = favstop_buses.filter({
                    let didntArriveYet: Bool = $0["predictedArrivalTime"].intValue > currentTime;
                    let onFavRoute: Bool = $0["routeId"].stringValue == favoriteRouteStop.routeId;
                    print ("\(didntArriveYet && onFavRoute)");
                    return didntArriveYet && onFavRoute })
                favstop_buses.sortInPlace({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                if favstop_buses.count > 0 {
                    //Build the RouteNum by combining Bus Number and Bus Compass direction)
                    self.favoriteList.append(favstop_buses[0])
                    //let busDirection = responseJSON["data"]["references"]["stops"][0]["direction"]
                    self.favoriteStopList.append(responseJSON["data"]["references"]["stops"][0])
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
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //stop polling for locations after first time (don't expect hte user to move particularly far before closing the today widget) TODO
        locationManager.stopUpdatingLocation()

        
        //println("locations = \(locations)")
        let latValue = locationManager.location!.coordinate.latitude
        let lonValue = locationManager.location!.coordinate.longitude
        print("\(latValue)")
        print("\(lonValue)")
        
        Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=org.onebusaway.iphone&app_uid=1EC3E57A-B013-40CC-A495-4F0A3CB2FC79&app_ver=2.2.1&lat=\(latValue)&lon=\(lonValue)&latSpan=0.002960&lonSpan=0.004426&version=2")
            .responseJSON { response in
                var responseJSON: SwiftyJSON.JSON = SwiftyJSON.JSON.null
                
                switch response.result {
                case .Success:
                    print("Validation Successful")
                    if (response.result.value != nil) {
                        responseJSON = SwiftyJSON.JSON(response.result.value!)
                    }
                case .Failure(let error):
                    debugPrint(error)
                    self.networkError = true
                    return
                }
                
                let stops: Array<JSON> = responseJSON["data"]["list"].arrayValue
                
                print("stops count = \(stops.count)")
                switch stops.count {
                case 2..<Int.max:
                    //println("Case 2")
                    let stop0_id: SwiftyJSON.JSON = stops[0]["id"]
                    let stop1_id: SwiftyJSON.JSON = stops[1]["id"]

                    Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop0_id).json?key=org.onebusaway.iphone&version=2")
                        .responseJSON { response in
                            var responseJSON: SwiftyJSON.JSON = SwiftyJSON.JSON.null
                            
                            switch response.result {
                            case .Success:
                                print("Validation Successful")
                                if (response.result.value != nil) {
                                    responseJSON = SwiftyJSON.JSON(response.result.value!)
                                }
                            case .Failure(let error):
                                debugPrint(error)
                                self.networkError = true
                                return
                            }
                            
                            var stop0_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                            let currentTime: Int = responseJSON["currentTime"].intValue

                            stop0_buses = stop0_buses.filter({
                                $0["predictedArrivalTime"].intValue > currentTime})
                            stop0_buses.sortInPlace({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                            self.nearbyStopOneBusList = stop0_buses;
                            self.nearbyStopOneList = stops[0];
                    }
                            //println("\(stop1_id)")
                            Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop1_id).json?key=org.onebusaway.iphone&version=2")
                                .responseJSON { response in
                                    var responseJSON: SwiftyJSON.JSON = SwiftyJSON.JSON.null
                                    
                                    switch response.result {
                                    case .Success:
                                        print("Validation Successful")
                                        if (response.result.value != nil) {
                                            responseJSON = SwiftyJSON.JSON(response.result.value!)
                                        }
                                    case .Failure(let error):
                                        debugPrint(error)
                                        self.networkError = true
                                        return
                                    }
                                    
                                    var stop1_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                                    let currentTime: Int = responseJSON["currentTime"].intValue

                                    stop1_buses = stop1_buses.filter({
                                        $0["predictedArrivalTime"].intValue > currentTime})
                                    stop1_buses.sortInPlace({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                                    
                                    
                                    self.nearbyStopTwoBusList = stop1_buses;
                                    self.nearbyStopTwoList = stops[1];
                    }
                case 1:
                    
                    //println("Case 1")
                    let stop0_id: SwiftyJSON.JSON = stops[0]["id"]
                    //println("\(stop0_id)")
                    Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/\(stop0_id).json?key=org.onebusaway.iphone&version=2")
                        .responseJSON { response in
                            var responseJSON: SwiftyJSON.JSON = SwiftyJSON.JSON.null
                            
                            switch response.result {
                            case .Success:
                                print("Validation Successful")
                                if (response.result.value != nil) {
                                    responseJSON = SwiftyJSON.JSON(response.result.value!)
                                }
                            case .Failure(let error):
                                debugPrint(error)
                                self.networkError = true
                                return
                            }
                            
                            var stop0_buses: Array<JSON> = responseJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue
                            
                            let currentTime: Int = responseJSON["currentTime"].intValue

                            stop0_buses = stop0_buses.filter({
                                $0["predictedArrivalTime"].intValue > currentTime})
                            stop0_buses.sortInPlace({$0["predictedArrivalTime"].intValue < $1["predictedArrivalTime"].intValue})
                            
                            self.nearbyStopOneBusList = stop0_buses;
                            self.nearbyStopOneList = stops[0];
                    }
                case 0:
                    print("Case 0")
                default:
                    
                    print("Case Default")
                }
                
                
                
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //return min(nearbyStopTwoBusList.count > 0 ? 1 : 0 + nearbyStopOneBusList.count > 0 ? 1 : 0 + favoriteList.count > 0 ? 1 : 0,1)
        return 3

    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 2: //nearby Routes
            if nearbyStopTwoBusList.count > 0  {
                let stopName = nearbyStopTwoList["name"]
                return "\(stopName)"
            }
            else {
                return ""
            }
        case 1: //nearby Routes
            if nearbyStopOneBusList.count > 0  {
                let stopName = nearbyStopOneList["name"]
                return "\(stopName)"
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
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor.whiteColor()
        header.textLabel!.font = UIFont(name: "Helventica Neue", size: 11)
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2: //nearby Routes 2
            if nearbyStopTwoBusList.count < 1 {
                return 0
            }
            return min(nearbyStopTwoBusList.count, TableViewConstants.maxRowCount - favoriteList.count - tableView.numberOfRowsInSection(1))
            
        case 1: //nearby Routes 1
            if nearbyStopOneBusList.count < 1 {
                return 0
            }
            return min(nearbyStopOneBusList.count, TableViewConstants.maxRowCount - favoriteList.count)
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
        if nearbyStopOneBusList.count  > 0 || nearbyStopTwoBusList.count  > 0 || (favoriteList.count > 0 && indexPath.section == 0){
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as! busViewCell
            if indexPath.section == 2 {
                configureBusItemCell(cell, busJSON: nearbyStopTwoBusList[indexPath.row], busStopJSON: nearbyStopTwoList)
            }else if indexPath.section == 1 {
                configureBusItemCell(cell, busJSON: nearbyStopOneBusList[indexPath.row], busStopJSON: nearbyStopOneList)
            }
            else {
                configureBusItemCell(cell, busJSON: favoriteList[indexPath.row], busStopJSON: favoriteStopList[indexPath.row])
            }
            cell.textLabel!.text = ""
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) 
            if networkError {
                cell.textLabel!.text = NSLocalizedString("Network Error", comment: "")
            }
            else{
                cell.textLabel!.text = NSLocalizedString("No Nearby buses and running Favorites.", comment: "")
            }
            cell.textLabel!.textColor = UIColor.lightTextColor()
            return cell
        }
    }
    
    func configureBusItemCell(itemCell: busViewCell, busJSON: SwiftyJSON.JSON, busStopJSON: SwiftyJSON.JSON) {
        let busDirection = busStopJSON["direction"]
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
