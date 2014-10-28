// Playground - noun: a place where people can play

import UIKit
import Alamofire
import SwiftyJSON
import XCPlayground


var waiting = true

var str = "Hello, playground"
var respondJSON: SwiftyJSON.JSON = SwiftyJSON.JSON.nullJSON
let favStopId = "1_13460"
let favRouteId = "40_100236"
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
                respondJSON = responseJSON
            waiting = false
            }
while(waiting) {
    NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate())
    usleep(10)
}
println("\(respondJSON)")

let currentTime: Int = respondJSON["currentTime"].intValue
var favstop_buses: Array<SwiftyJSON.JSON> = respondJSON["data"]["entry"]["arrivalsAndDepartures"].arrayValue

println("\(favstop_buses)")
favstop_buses.sort({$0["predictedArrivalTime"].intValue > $1["predictedArrivalTime"].intValue})
favstop_buses = favstop_buses.filter({
    var didntArriveYet: Bool = $0["predictedArrivalTime"].intValue > currentTime;
    //var onFavRoute: Bool = $0["routeId"].stringValue == favRouteId;
     var onFavRoute: Bool = true
    return (didntArriveYet && onFavRoute) })
println("\(favstop_buses)")
if favstop_buses.count > 0 {
    //we pick the first bus that is predicted to arrive AFTER current time
    //yes this is ghetto TODO
    
    //for
    //                    var i_arrival: Int = favstop_buses[i]e
    
    
    //Build the RouteNum by combining Bus Number and Bus Compass direction)
    //                    let busNum = favstop_buses[i]["routeShortName"]
    let busDirection = respondJSON["data"]["references"]["stops"][0]["direction"]
    //                "\(busNum)\(busDirection)"
    
    //Json provides epoch time in milliseconds were converting to seconds.
    //                let busPredictedArrivalEpochTime = favstop_buses[i]["predictedArrivalTime"].doubleValue/1000
    let now = NSDate()

//Display Minutes to bus arrival
//I could use NSDate to compare now and arrival, i shoudldo that maybe?
//this works for now TODO
//                String(Int((busPredictedArrivalEpochTime - now.timeIntervalSince1970)/60))

//Display arrival time in 12:00 AM format
//                let arrival = NSDate(timeIntervalSince1970: busPredictedArrivalEpochTime)
//                let hhmmFormatter = NSDateFormatter()
//                hhmmFormatter.dateFormat = "h:mm a"
//                hhmmFormatter.stringFromDate(arrival)
}
