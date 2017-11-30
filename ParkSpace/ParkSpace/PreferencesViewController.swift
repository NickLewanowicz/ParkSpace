//
//  PreferencesViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-30.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import Cheers

class PreferencesViewController: UITableViewController {
    let NUM_SECTIONS = 1
    let NUM_ROWS_PREFS_SECTION = 2
    let HEIGHT_FOR_SECTION : CGFloat = 46
    
    let cheerView = CheerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfetti()
        
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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Night Mode is currently under construction"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let nightSwitch = UISwitch(frame: .zero) as UISwitch
            nightSwitch.isOn = true
            nightSwitch.addTarget(self, action: #selector(nightSwitchTriggered), for: .valueChanged)
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            cell.cellLabel.text = "Night Mode"
            cell.cellImageView.image = #imageLiteral(resourceName: "PSS_NightMode")
            cell.accessoryView = nightSwitch
            cell.contentMode = .scaleAspectFit
            return cell
        } else {
            let coolSwitch = UISwitch(frame: .zero) as UISwitch
            coolSwitch.isOn = false
            coolSwitch.addTarget(self, action: #selector(coolSwitchTriggered), for: .valueChanged)
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            cell.cellLabel.text = "Cool Mode"
            cell.cellImageView.image = #imageLiteral(resourceName: "PSS_FAQ")
            cell.accessoryView = coolSwitch
            cell.contentMode = .scaleAspectFit
            return cell
        }
    }
    
    func nightSwitchTriggered(sender: UISwitch) {
        print("night switched")
    }
    
    func coolSwitchTriggered(sender: UISwitch) {
        print("cool switched")
        
        if sender.isOn {
            startConfetti()
        } else {
            stopConfetti()
        }
    }
    
    func setupConfetti() {
        view.addSubview(cheerView)
        cheerView.config.particle = .confetti
    }
    
    func startConfetti() {
        cheerView.start()
    }
    
    func stopConfetti() {
        cheerView.stop()
    }
    
}
