//
//  RentViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-13.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import ChameleonFramework
import NHRangeSlider
import Stripe

let imageCache = NSCache<NSString, AnyObject>()

class RentViewController: UIViewController, NHRangeSliderViewDelegate, STPPaymentMethodsViewControllerDelegate {
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var spotImageButton: UIButton!
    @IBOutlet weak var mondayButton: UIButton!
    @IBOutlet weak var tuesdayButton: UIButton!
    @IBOutlet weak var wednesdayButton: UIButton!
    @IBOutlet weak var thursdayButton: UIButton!
    @IBOutlet weak var fridayButton: UIButton!
    @IBOutlet weak var saturdayButton: UIButton!
    @IBOutlet weak var sundayButton: UIButton!
    
    @IBOutlet weak var parkLabel: UILabel!
    @IBOutlet weak var timeRangeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var paymentButton: UIButton!
    @IBOutlet weak var rentButton: UIButton!
    
    var sliderView : NHRangeSliderView?
    var arrayOfDays : [UIButton] = []
    var arrayOfAvailableDays : [Int] = []
    var arrayOfDayLabels :[String] = []
    var spotData : NSDictionary?
    var selectedDay : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProperties()
        setupUIElements()
        setupRangeSlider()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSpotImage()
    }
    
    func setupProperties() {
        self.descriptionTextView.isEditable = false
        arrayOfDays = [mondayButton, tuesdayButton, wednesdayButton, thursdayButton, fridayButton, saturdayButton, sundayButton]
    
        let address = spotData!["address"]
        let rate = spotData!["rate"]
        var description : String
        if let desc = spotData!["description"] {
            description = (desc as? String)!
        } else {
            description = "No description provided"
        }
        
        addressLabel.text = address as? String
        rateLabel.text = "$\(String(format:"%.02f", (rate as? Float)!))/hr"
        descriptionTextView.text = description
    }
    
    fileprivate func setupRangeSlider() {
        sliderView = NHRangeSliderView(frame: CGRect(x: 46, y: 380, width: self.view.bounds.width - 88, height: 80))
        let earliestTime = (spotData!["fromTime"] as? Double)!
        let latestTime = (spotData!["toTime"] as? Double)!
        
        sliderView?.maximumValue = latestTime
        sliderView?.minimumValue = earliestTime
        sliderView?.upperValue = latestTime
        sliderView?.lowerValue = earliestTime
        sliderView?.lowerDisplayStringFormat = convertMinutesToTime(minutes: Int(earliestTime))
        sliderView?.upperDisplayStringFormat = convertMinutesToTime(minutes: Int(latestTime))
        sliderView?.trackHighlightTintColor = UIColor(hexString: "19E698")!
        sliderView?.gapBetweenThumbs = 60
        sliderView?.sizeToFit()
        sliderView?.delegate = self
        self.view.addSubview(sliderView!)
        setupSliderPlacement()
        
        let lowerVal = Int((sliderView?.lowerValue)!)
        let upperVal = Int((sliderView?.upperValue)!)
        let minuteRange = upperVal - lowerVal
        let rate = spotData!["rate"] as? Double
        timeRangeLabel.text = "\(convertMinutesToTime(minutes: lowerVal)) - \(convertMinutesToTime(minutes: upperVal))"
        priceLabel.text = "Price: $\(String(format: "%.2f", (Double(minuteRange / 60) * rate!)))CAD"
    }
    
    func setupUIElements() {
        paymentButton.layer.borderWidth = 1
        paymentButton.layer.borderColor = UIColor(hexString: "19E698")?.cgColor
        paymentButton.layer.cornerRadius = 6
        rentButton.layer.cornerRadius = 6    
        
        arrayOfAvailableDays = spotData!["availableDays"] as? NSArray as! [Int]
        let currDayIndex = convertToProperIndex(Calendar.current.dateComponents([.weekday], from: Date()).weekday!)
        arrayOfDayLabels = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        for i in stride(from: currDayIndex, to: currDayIndex + 7, by: 1) {
            arrayOfDays[i - currDayIndex].setTitle(arrayOfDayLabels[i % 7], for: .normal)
        }
        for (index, day) in arrayOfDays.enumerated() {
            day.layer.cornerRadius = 4
            day.layer.borderWidth = 1
            day.layer.borderColor = UIColor.darkGray.cgColor
            if arrayOfAvailableDays[(index + currDayIndex) % 7] == 0 {
                day.backgroundColor = UIColor(hexString: "F7F7F7")
                day.layer.borderColor = UIColor(hexString: "dbdbdb")?.cgColor
                day.setTitleColor(UIColor(hexString: "dbdbdb"), for: .normal)
                day.isEnabled = false
            }
        }
        
    }
    
    func convertToProperIndex(_ day: Int) -> Int {
        var newIndex = day - 2
        if newIndex < 0 {
            newIndex = 6
        }
        return newIndex
    }
    
    func setupSpotImage() {
        if let imgURL = spotData!["imageURL"] as? String, imgURL != "None" {
            //check cache for image first
            self.spotImageButton.loadingIndicator(show: true)
            if let cachedImage = imageCache.object(forKey: imgURL as NSString) as? UIImage {
                self.spotImageButton.setImage(cachedImage, for: .normal)
                self.spotImageButton.loadingIndicator(show: false)
                return
            }
            
            let url = URL(string: imgURL)
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                //download hit an error so lets return out
                if let error = error {
                    print(error)
                    self.spotImageButton.loadingIndicator(show: false)
                    return
                }
                DispatchQueue.main.async(execute: {
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: imgURL as NSString)
                        self.spotImageButton.setImage(downloadedImage, for: .normal)
                        self.spotImageButton.loadingIndicator(show: false)
                    }
                })
            }).resume()
        }
    }
    
    func sliderValueChanged(slider: NHRangeSlider?) {
        let lowerVal = Int((slider?.lowerValue)!)
        let upperVal = Int((slider?.upperValue)!)
        let minuteRange = upperVal - lowerVal
        let rate = spotData!["rate"] as? Double
        priceLabel.text = "Price: $\(String(format: "%.2f", (Double(minuteRange / 60) * rate!)))CAD"
        timeRangeLabel.text = "\(convertMinutesToTime(minutes: lowerVal)) - \(convertMinutesToTime(minutes: upperVal))"
    }
    
    func convertMinutesToTime(minutes: Int) -> String {
        var hours = minutes / 60
        let mins = (minutes % 60) < 10 ? "0\(minutes % 60)" : "\(minutes % 60)"
        var zone = "AM"
        if hours > 12 {
            hours = hours % 12
            zone = "PM"
        }
        return "\(hours):\(mins) \(zone)"
    }
    
    func setupSliderPlacement() {
        self.sliderView?.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 32).isActive = true
        self.sliderView?.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 32).isActive = true
        self.sliderView?.heightAnchor.constraint(equalToConstant: 80).isActive = true
        self.sliderView?.topAnchor.constraint(equalTo: self.parkLabel.bottomAnchor, constant: 8).isActive = true
    }
    @IBAction func dayButtonTapped(_ sender: UIButton) {
        for day in arrayOfDays {
            if day.backgroundColor == UIColor(hexString: "19E698")! {
                day.backgroundColor = UIColor(hexString: "FFFFFF")!
                day.setTitleColor(UIColor(hexString: "555555")!, for: .normal)
            }
        }
        sender.backgroundColor = UIColor(hexString: "19E698")!
        sender.setTitleColor(UIColor.white, for: .normal)
        let currDayIndex = convertToProperIndex(Calendar.current.dateComponents([.weekday], from: Date()).weekday!)
        selectedDay = (sender.tag - 1 + currDayIndex) % 7
        print(arrayOfDayLabels[selectedDay!])
    }
    @IBAction func didTapPaymentMethod(_ sender: UIButton) {
        let customerContext = STPCustomerContext(keyProvider: MainAPIClient.shared)
        let paymentMethodsViewController = STPPaymentMethodsViewController(configuration: STPPaymentConfiguration.shared(), theme: STPTheme.default(), customerContext: customerContext, delegate: self)
        let navigationController = UINavigationController(rootViewController: paymentMethodsViewController)
        present(navigationController, animated: true)
    }
    
    
    func paymentMethodsViewController(_ paymentMethodsViewController: STPPaymentMethodsViewController, didFailToLoadWithError error: Error) {
        // Dismiss payment methods view controller
        dismiss(animated: true)
        
        // Present error to user...
    }
    
    func paymentMethodsViewControllerDidCancel(_ paymentMethodsViewController: STPPaymentMethodsViewController) {
        // Dismiss payment methods view controller
        dismiss(animated: true)
    }
    
    func paymentMethodsViewControllerDidFinish(_ paymentMethodsViewController: STPPaymentMethodsViewController) {
        // Dismiss payment methods view controller
        dismiss(animated: true)
    }
    
    func paymentMethodsViewController(_ paymentMethodsViewController: STPPaymentMethodsViewController, didSelect paymentMethod: STPPaymentMethod) {
        // Save selected payment method
        //selectedPaymentMethod = paymentMethod
    }
}

extension UIButton {
    func loadingIndicator(show: Bool) {
        if show {
            let indicator = UIActivityIndicatorView()
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            self.addSubview(indicator)
            indicator.startAnimating()
        } else {
            for view in self.subviews {
                if let indicator = view as? UIActivityIndicatorView {
                    indicator.stopAnimating()
                    indicator.removeFromSuperview()
                }
            }
        }
    }
}


