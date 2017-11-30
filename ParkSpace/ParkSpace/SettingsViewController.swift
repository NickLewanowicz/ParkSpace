//
//  SettingsViewController.swift
//  ParkSpace
//
//  Created by Connor Maloney on 2017-09-25.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import Firebase
import Alertift

class SettingsViewController: UITableViewController {
    let NUM_SECTIONS = 3
    let NUM_ROWS_PROFILE_SECTION = 1
    let NUM_ROWS_SETTINGS_SECTION = 3
    let NUM_ROWS_LOGOUT_SECTION = 1
    let HEIGHT_FOR_PROFILE_SECTION : CGFloat = 58
    let HEIGHT_FOR_SETTINGS_SECTION : CGFloat = 46
    
    let settingsCellLabels = ["Preferences", "FAQ", "Contact Us"]
    let settingsCellImages = ["PSS_Settings", "PSS_FAQ", "PSS_Contact"]
    
    //MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib.init(nibName: "ProfileCellView", bundle: nil), forCellReuseIdentifier: "ProfileCell")
        tableView.register(UINib.init(nibName: "SettingsCellView", bundle: nil), forCellReuseIdentifier: "SettingsCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    //MARK: Table View Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return NUM_SECTIONS
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return NUM_ROWS_PROFILE_SECTION
        case 1:
            return NUM_ROWS_SETTINGS_SECTION
        case 2:
            return NUM_ROWS_LOGOUT_SECTION
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return HEIGHT_FOR_PROFILE_SECTION
        } else {
            return HEIGHT_FOR_SETTINGS_SECTION
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "COMP3004: ParkSpace by Team Moon"
        }
        return nil
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
            let uid = FIRAuth.auth()?.currentUser?.uid
            let userRef = FIRDatabase.database().reference().child("users").child(uid!)
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let json = snapshot.value as? [String : AnyObject] else {
                    return
                }
                cell.profileNameLabel.text = json["name"] as? String
            }, withCancel: nil)
            cell.profileImageView.image = #imageLiteral(resourceName: "PSS_Profile")
            cell.profileImageView.contentMode = .scaleAspectFit
            cell.accessoryType = .disclosureIndicator
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            cell.cellLabel.text = settingsCellLabels[indexPath.row]
            cell.cellImageView.image = UIImage.init(named: settingsCellImages[indexPath.row])
            cell.cellImageView.contentMode = .scaleAspectFit
            cell.accessoryType = .disclosureIndicator
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            cell.cellLabel.text = "Sign Out"
            cell.cellImageView.image = #imageLiteral(resourceName: "PSS_SignOut")
            cell.cellImageView.contentMode = .scaleAspectFit
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let profileViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
            self.navigationController?.pushViewController(profileViewController, animated: true)
        case 1:
            switch indexPath.row {
                case 0:
                    let preferencesViewController = self.storyboard?.instantiateViewController(withIdentifier: "PreferencesView") as! PreferencesViewController
                    self.navigationController?.pushViewController(preferencesViewController, animated: true)
                case 1:
                    let faqViewController = self.storyboard?.instantiateViewController(withIdentifier: "FAQView")
                    self.navigationController?.pushViewController(faqViewController!, animated: true)
                case 2:
                    let contactViewController = self.storyboard?.instantiateViewController(withIdentifier: "ContactView")
                    self.navigationController?.pushViewController(contactViewController!, animated: true)
                default:
                    print("Error: Row")
            }
        case 2:
            Alertift.alert(title: "Sign Out", message: "Are you sure want to sign out of ParkSpace?")
                .action(.destructive("Sign Out")) { _ in
                    self.handleLogout()
                }
                .action(.cancel("Cancel")) { _ in
                    self.tableView.reloadData()
                }
                .show(on: self, completion: {
                    self.tableView.reloadData()
                })
        default:
            print("Error: Section")
        }
    }
    
    //MARK: Handler Methods
    func handleLogout() {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginRegisterViewController = LoginRegisterViewController()
        let mapViewController = MapViewController()
        loginRegisterViewController.mapController = mapViewController
        present(loginRegisterViewController, animated: true, completion: nil)
    }
}
