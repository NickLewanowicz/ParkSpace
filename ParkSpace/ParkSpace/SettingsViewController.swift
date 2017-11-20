//
//  SettingsViewController.swift
//  ParkSpace
//
//  Created by Connor Maloney on 2017-09-25.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UITableViewController {

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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            print("Profile")
        case 1:
            switch indexPath.row {
                case 0:
                    print("Preferences")
                case 1:
                    print("FAQ")
                case 2:
                    print("Contact US")
                default:
                    print("Error: Row")
            }
        case 2:
            print("Sign Out")
            self.handleLogout()
        default:
            print("Error: Section")
        }
    }
    
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
