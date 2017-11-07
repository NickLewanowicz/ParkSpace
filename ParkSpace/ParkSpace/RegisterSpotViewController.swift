//
//  RegisterSpotViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-07.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit

class RegisterSpotViewController: UIViewController {
    
    @IBOutlet weak var addressLabel: UILabel!
    //MARK: Spot Properties
    var spotLatitude : Double? = nil
    var spotLongitude: Double? = nil
    var spotAddress  : String? = nil
    var spotCity     : String? = nil
    var spotAvailableDays : [Int] = [0,0,0,0,0,0,0] //monday -> [0], sunday -> [6]
    var spotAvailableFrom : Int? = nil //minutes since the start of day
    var spotAvailableTo   : Int? = nil //minutes since the start of day, > spotAvailableFrom
    var spotHourlyPrice   : Double? = nil //Hourly rate in CAD

    override func viewDidLoad() {
        super.viewDidLoad()
        addressLabel.text = spotAddress
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
