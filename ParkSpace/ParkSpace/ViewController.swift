//
//  ViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-09-07.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        present(LoginRegisterViewController(), animated: true, completion: nil)
    }


}

