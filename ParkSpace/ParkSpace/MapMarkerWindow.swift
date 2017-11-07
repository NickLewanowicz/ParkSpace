//
//  MapMarkerWindow.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-06.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit

class MapMarkerWindow: UIView {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var availibilityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    
    @IBAction func didTapInfoButton(_ sender: UIButton) {
        print("tapped")
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "MapMarkerWindowView", bundle: nil).instantiate(withOwner: self, options: nil).first as! UIView
    }
}
