//  HostViewController.swift
//  Created by Connor Maloney on 2017-09-26.

import UIKit
import ChameleonFramework
import GooglePlaces

class HostViewController: UIViewController, SWRevealViewControllerDelegate, GMSAutocompleteViewControllerDelegate {

    @IBOutlet weak var navBarButton: UIButton!
    @IBOutlet weak var registerSpotButton: UIButton!
    @IBOutlet weak var addressFieldButton: UIButton!
    
    @IBOutlet weak var mondayButton: UIButton!
    @IBOutlet weak var tuesdayButton: UIButton!
    @IBOutlet weak var wednesdayButton: UIButton!
    @IBOutlet weak var thursdayButton: UIButton!
    @IBOutlet weak var fridayButton: UIButton!
    @IBOutlet weak var saturdayButton: UIButton!
    @IBOutlet weak var sundayButton: UIButton!
    
    @IBOutlet weak var fromTimeSlotField: UITextField!
    @IBOutlet weak var toTimeSlotField: UITextField!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceSlider: UISlider!
    
    var spotLatitude : Double? = nil
    var spotLongitude: Double? = nil
    var spotAddress  : String? = nil
    var spotCity     : String? = nil
    var spotAvailableDays : [Int] = [0,0,0,0,0,0,0] //monday -> [0], sunday -> [6]
    var spotAvailableFrom : Int? = nil
    var spotAvailableTo   : Int? = nil
    var spotHourlyPrice   : Double? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.revealViewController().delegate = self
        sideMenus()
        
        setupUIElements()
    }

    fileprivate func setupUIElements() {
        navBarButton.tintColor = UIColor.darkGray
        registerSpotButton.layer.cornerRadius = 6
        addressFieldButton.layer.borderWidth = 1
        addressFieldButton.layer.borderColor = UIColor.darkGray.cgColor
        
        mondayButton.layer.cornerRadius = 4
        mondayButton.layer.borderWidth = 1
        mondayButton.layer.borderColor = UIColor.darkGray.cgColor
        
        tuesdayButton.layer.cornerRadius = 4
        tuesdayButton.layer.borderWidth = 1
        tuesdayButton.layer.borderColor = UIColor.darkGray.cgColor
        
        wednesdayButton.layer.cornerRadius = 4
        wednesdayButton.layer.borderWidth = 1
        wednesdayButton.layer.borderColor = UIColor.darkGray.cgColor
        
        thursdayButton.layer.cornerRadius = 4
        thursdayButton.layer.borderWidth = 1
        thursdayButton.layer.borderColor = UIColor.darkGray.cgColor
        
        fridayButton.layer.cornerRadius = 4
        fridayButton.layer.borderWidth = 1
        fridayButton.layer.borderColor = UIColor.darkGray.cgColor
        
        saturdayButton.layer.cornerRadius = 4
        saturdayButton.layer.borderWidth = 1
        saturdayButton.layer.borderColor = UIColor.darkGray.cgColor
        
        sundayButton.layer.cornerRadius = 4
        sundayButton.layer.borderWidth = 1
        sundayButton.layer.borderColor = UIColor.darkGray.cgColor
        
        priceSlider.minimumValue = 0.50
        priceSlider.maximumValue = 4.00
        priceSlider.value = 1.50
        
        spotHourlyPrice = Double(priceSlider.value)
    }
    
    @IBAction func addressFieldButtonTapped(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func dayButtonTapped(_ sender: UIButton) {
        if sender.backgroundColor != UIColor(hexString: "19E698")!{
            sender.backgroundColor = UIColor(hexString: "19E698")!
            sender.setTitleColor(UIColor.white, for: .normal)
            self.spotAvailableDays[sender.tag - 1] = 1
        } else {
            sender.backgroundColor = UIColor.white
            sender.setTitleColor( UIColor(hexString: "555555")!, for: .normal)
            self.spotAvailableDays[sender.tag - 1] = 0
        }
    }
    
    @IBAction func priceSliderDidChange(_ sender: UISlider) {
        let step: Float = 0.05
        let currentValue = roundf(sender.value / step) * step
        self.priceLabel.text = "$\(String(format:"%.02f", currentValue))"
        spotHourlyPrice = Double(priceSlider.value)
    }
    
    @IBAction func fromTimeSlotEdited(_ sender: UITextField) {
        let datePickerView  : UIDatePicker = UIDatePicker()
        let toolBar = UIToolbar().ToolbarPiker(mySelect: #selector(dismissPicker))
        datePickerView.datePickerMode = .time
        fromTimeSlotField.inputView = datePickerView
        fromTimeSlotField.inputAccessoryView = toolBar
        datePickerView.addTarget(self, action: #selector(handleFromDatePicker(sender:)), for: .valueChanged)
    }
    
    @IBAction func toTimeSlotEdited(_ sender: UITextField) {
        let datePickerView  : UIDatePicker = UIDatePicker()
        let toolBar = UIToolbar().ToolbarPiker(mySelect: #selector(dismissPicker))
        datePickerView.datePickerMode = .time
        toTimeSlotField.inputView = datePickerView
        toTimeSlotField.inputAccessoryView = toolBar
        datePickerView.addTarget(self, action: #selector(handleToDatePicker(sender:)), for: .valueChanged)
    }
    
    func handleFromDatePicker(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        fromTimeSlotField.text = dateFormatter.string(from: sender.date)
        spotAvailableFrom = getMinutesSinceStartOfDay(timeString: dateFormatter.string(from: sender.date))
    }
    
    func handleToDatePicker(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        toTimeSlotField.text = dateFormatter.string(from: sender.date)
        spotAvailableTo = getMinutesSinceStartOfDay(timeString: dateFormatter.string(from: sender.date))
    }
    
    func getMinutesSinceStartOfDay(timeString time: String) -> Int {
        let firstSplit = time.components(separatedBy: ":")
        let secondSplit = firstSplit[1].components(separatedBy: " ")
        let hours = Int(firstSplit[0])
        let minutes = Int(secondSplit[0])
        let AMorPM = secondSplit[1]
        
        var minutesSinceMidnight = 0
        minutesSinceMidnight += hours! * 60
        minutesSinceMidnight += minutes!
        minutesSinceMidnight += (AMorPM == "PM") ? 12 * 60 : 0
        
        return minutesSinceMidnight
    }
    
    func sideMenus() {
        if revealViewController() != nil {
            navBarButton.addTarget(revealViewController, action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
            revealViewController().rearViewRevealWidth = 275
            revealViewController().rightViewRevealWidth = 160
        }
    }
    
    func dismissPicker() {
        view.endEditing(true)
    }
}

extension HostViewController {
    //Handle the users selection
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.addressFieldButton.setTitle(place.formattedAddress!, for: .normal)
        
        self.spotLatitude = place.coordinate.latitude
        self.spotLongitude = place.coordinate.longitude
        self.spotAddress = place.name
        self.spotCity = place.addressComponents![3].name
        
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension UIToolbar {
    
    func ToolbarPiker(mySelect : Selector) -> UIToolbar {
        
        let toolBar = UIToolbar()
        
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.black
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: mySelect)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([ spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }
    
}
