//
//  ViewController.swift
//  Musait Yerde
//
//  Created by Saruhan on 5-10-14.
//  Copyright (c) 2014 KaraBal. All rights reserved.
// stolen from http://www.glimsoft.com/06/28/ios-8-today-extension-tutorial/

import UIKit

//Crappy picker for preferred bus route picker
//currently the routes need to be resolved to their
class ViewController: UIViewController {
    var sharedDefaults = NSUserDefaults(suiteName: "group.Musait-Yerde")
    
    @IBOutlet var textField: UITextField!
    @IBAction func setButtonPressed(sender: AnyObject) {

        }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sharedDefaults?.setObject("teststring", forKey: "numberPass")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

