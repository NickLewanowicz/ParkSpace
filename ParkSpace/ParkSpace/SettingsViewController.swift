//
//  SettingsViewController.swift
//  ParkSpace
//
//  Created by Connor Maloney on 2017-09-25.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var navBarButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
