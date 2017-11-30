//
//  ProfileViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-29.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import Firebase
import Alertift

class ProfileViewController: UITableViewController {
    let NUM_SECTIONS = 2
    let NUM_ROWS_NAME_SECTION = 1
    let NUM_ROWS_EMAIL_SECTION = 1
    let HEIGHT_FOR_SETTINGS_SECTION : CGFloat = 46
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib.init(nibName: "SettingsCellView", bundle: nil), forCellReuseIdentifier: "SettingsCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return NUM_SECTIONS
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return NUM_ROWS_NAME_SECTION
        case 1:
            return NUM_ROWS_EMAIL_SECTION
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return HEIGHT_FOR_SETTINGS_SECTION
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Name"
        case 1:
            return "Email"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            let uid = FIRAuth.auth()?.currentUser?.uid
            let userRef = FIRDatabase.database().reference().child("users").child(uid!)
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let json = snapshot.value as? [String : AnyObject] else {
                    return
                }
                cell.cellLabel.text = json["name"] as? String
            }, withCancel: nil)
            cell.cellImageView.image = #imageLiteral(resourceName: "PSS_Profile")
            cell.cellImageView.contentMode = .scaleAspectFit
            cell.accessoryType = .disclosureIndicator
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
            cell.cellLabel.text = FIRAuth.auth()?.currentUser?.email
            cell.cellImageView.image = #imageLiteral(resourceName: "PSS_Contact")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            Alertift.alert(title: "Change Name", message: "Enter your desired name")
                .textField(configurationHandler: { (textfield) in
                    let uid = FIRAuth.auth()?.currentUser?.uid
                    let userRef = FIRDatabase.database().reference().child("users").child(uid!)
                    userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        guard let json = snapshot.value as? [String : AnyObject] else {
                            return
                        }
                        textfield.text = json["name"] as? String
                    }, withCancel: nil)
                })
                .action(.cancel("Cancel"))
                .action(.default("Confirm")) { _, _, textFields in
                    let name = textFields?.first?.text ?? ""
                    if name != "" {
                        self.updateUserName(newName: name)
                        self.tableView.reloadData()
                    }
                }
                .show(on: self, completion: {
                    self.tableView.reloadData()
                })
        } else {
            Alertift.alert(title: "Sign in", message: "In order to change your email, please sign in.")
                .textField { textField in
                    textField.placeholder = "Email"
                }
                .textField { textField in
                    textField.placeholder = "Password"
                    textField.isSecureTextEntry = true
                }
                .action(.cancel("Cancel"))
                .action(.default("Sign in")) { _, _, textFields in
                    let email = textFields?.first?.text ?? ""
                    let password = textFields?.last?.text ?? ""
                    let creds = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
                    FIRAuth.auth()?.currentUser?.reauthenticate(with: creds, completion: { (err) in
                        if err != nil {
                            print("error")
                        } else {
                            Alertift.alert(title: "Change Email", message: "Enter your new email")
                                .textField(configurationHandler: { (textfield) in
                                    textfield.text = FIRAuth.auth()?.currentUser?.email
                                })
                                .action(.cancel("Cancel"))
                                .action(.default("Confirm")) { _, _, textFields in
                                    let email = textFields?.first?.text ?? ""
                                    if email != "" {
                                        self.updateEmailInDB(newEmail: email)
                                        FIRAuth.auth()?.currentUser?.updateEmail(email, completion: { (error) in
                                            if error != nil {
                                                print("error updating email")
                                            }
                                            self.tableView.reloadData()
                                        })
                                    }
                                }
                                .show(on: self, completion: {
                                    self.tableView.reloadData()
                                })
                        }
                    })
                }
                .show(on: self, completion: {
                    self.tableView.reloadData()
                })
        }
    }
    
    func updateUserName(newName: String) {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let userRef = FIRDatabase.database().reference().child("users").child(uid!)
        let values = ["name": newName]
        userRef.updateChildValues(values)
    }
    
    func updateEmailInDB(newEmail: String) {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let userRef = FIRDatabase.database().reference().child("users").child(uid!)
        let values = ["email": newEmail]
        userRef.updateChildValues(values)
    }
}
