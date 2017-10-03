//
//  HostViewController.swift
//  
//
//  Created by Connor Maloney on 2017-09-26.
//
//

import UIKit

class HostViewController: UIViewController, SWRevealViewControllerDelegate {

    @IBOutlet weak var navBarButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.revealViewController().delegate = self
        
        // Call sidemenu on load
        sideMenus()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sideMenus() {
        if revealViewController() != nil {
            navBarButton.addTarget(revealViewController, action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
            revealViewController().rearViewRevealWidth = 275
            revealViewController().rightViewRevealWidth = 160
        }
    }

}
