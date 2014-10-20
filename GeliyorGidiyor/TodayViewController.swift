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


class TodayViewController: UIViewController, CLLocationManagerDelegate, NCWidgetProviding {
    
    let locationManager = CLLocationManager()
  
    override func viewDidLoad() {
        super.viewDidLoad()
        //init location manager delegate and request A8uthoriization from user
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        //test if authorization was given, if so try to determine Nearby Routes
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse)
        {
            locationManager.startUpdatingLocation()
            println("locations = \(locationManager)")
            var latValue = locationManager.location.coordinate.latitude
            var lonValue = locationManager.location.coordinate.longitude
            println("\(latValue)")
            println("\(lonValue)")
            
            Alamofire.request(.GET, "http://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=org.onebusaway.iphone&app_uid=1EC3E57A-B013-40CC-A495-4F0A3CB2FC79&app_ver=2.2.1&lat=\(latValue)&lon=\(lonValue)&latSpan=0.002960&lonSpan=0.004426&version=2")
                .responseJSON { (_, _, JSON, _) in
                    println(JSON)
                    
            }
                    }
        else
        {
            //todo add fallback. (reduce the  Nearby route UI views to zero?)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        
        //TODO~~this grabs the Favorite Bus route from the Parent App~~
        //let sharedDefaults = NSUserDefaults(suiteName: “group.YOURGROUPHERE”)
        
        //favRouteNum.text = sharedDefaults.objectForKey(“numberPass”) as String

        
        
        
        
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
 
}
