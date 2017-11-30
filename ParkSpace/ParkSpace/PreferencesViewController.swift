//
//  PreferencesViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-30.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit

class PreferencesViewController: UITableViewController {
    let NUM_SECTIONS = 1
    let NUM_ROWS_PREFS_SECTION = 1
    let HEIGHT_FOR_SECTION : CGFloat = 46

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib.init(nibName: "SettingsCellView", bundle: nil), forCellReuseIdentifier: "SettingsCell")
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return NUM_SECTIONS
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NUM_ROWS_PREFS_SECTION
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return HEIGHT_FOR_SECTION
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
        cell.cellLabel.text = "Night Mode"
        cell.cellImageView.image = #imageLiteral(resourceName: "PSS_NightMode")
        cell.accessoryType = .disclosureIndicator
        cell.contentMode = .scaleAspectFit
        
        return cell
    }
    
}
