//  HostViewController.swift
//  Created by Connor Maloney on 2017-09-26.

import UIKit
import ChameleonFramework
import GooglePlaces
import Firebase

class HostViewController: UIViewController, GMSAutocompleteViewControllerDelegate {
    //MARK: Outlets
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
    @IBOutlet weak var errorLabel: UILabel!
    
    //MARK: Spot Properties
    var spotLatitude : Double? = nil
    var spotLongitude: Double? = nil
    var spotAddress  : String? = nil
    var spotCity     : String? = nil
    var spotAvailableDays : [Int] = [0,0,0,0,0,0,0] //monday -> [0], sunday -> [6]
    var spotAvailableFrom : Int? = nil //minutes since the start of day
    var spotAvailableTo   : Int? = nil //minutes since the start of day, > spotAvailableFrom
    var spotHourlyPrice   : Double? = nil //Hourly rate in CAD
    
    var arrayOfDays : [UIButton] = []
    
    //MARK: Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProperties()
        setupUIElements()
    }
    
    //MARK: Event Handlers
    @IBAction func addressFieldButtonTapped(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        let filter = GMSAutocompleteFilter()
        filter.country = "CA"
        autocompleteController.delegate = self
        autocompleteController.autocompleteFilter = filter
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func dayButtonTapped(_ sender: UIButton) {
        if sender.backgroundColor != UIColor(hexString: "19E698")!{
            sender.backgroundColor = UIColor(hexString: "19E698")!
            sender.setTitleColor(UIColor.white, for: .normal)
            self.spotAvailableDays[sender.tag - 1] = 1
        } else {
            sender.backgroundColor = UIColor.white
            sender.setTitleColor(UIColor(hexString: "555555")!, for: .normal)
            self.spotAvailableDays[sender.tag - 1] = 0
        }
    }
    
    @IBAction func priceSliderDidChange(_ sender: UISlider) {
        let step: Float = 0.05
        let currentValue = roundf(sender.value / step) * step
        self.priceLabel.text = "$\(String(format:"%.02f", currentValue))"
        spotHourlyPrice = Double(String(format:"%.02f", currentValue))
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
    
    @IBAction func registerSpotButtonTapped(_ sender: UIButton) {
        if checkIfUserCanRegisterSpot() {
            errorLabel.text = nil
            let registerSpotViewController = self.storyboard?.instantiateViewController(withIdentifier: "RegisterSpotViewController") as! RegisterSpotViewController
            registerSpotViewController.spotLatitude = self.spotLatitude
            registerSpotViewController.spotLongitude = self.spotLongitude
            registerSpotViewController.spotAddress = self.spotAddress
            registerSpotViewController.spotCity = self.spotCity
            registerSpotViewController.spotAvailableDays = self.spotAvailableDays
            registerSpotViewController.spotAvailableFrom = self.spotAvailableFrom
            registerSpotViewController.spotAvailableTo = self.spotAvailableTo
            registerSpotViewController.spotHourlyPrice = self.spotHourlyPrice
            self.navigationController?.pushViewController(registerSpotViewController, animated: true)
            //registerSpot()
        }
    }
    
    //MARK: Supporting Methods
    func registerSpot() {
        let ref = FIRDatabase.database().reference().child("spots")
        let childRef = ref.childByAutoId()
        let userID = FIRAuth.auth()?.currentUser?.uid
        let timestamp = Int(NSDate.timeIntervalSinceReferenceDate)
        let values = ["userID": userID!, "address": spotAddress!, "city": spotCity!, "latitude": spotLatitude!, "longitude": spotLongitude!, "availableDays": spotAvailableDays, "fromTime": spotAvailableFrom!, "toTime": spotAvailableTo!, "rate": spotHourlyPrice!, "timestamp": timestamp] as [String : Any]
        
        childRef.updateChildValues(values) { (err, ref) in
            if err != nil {
                print(err.debugDescription)
                self.errorLabel.text = "Network error."
                return
            }
            //Success
            let alert = UIAlertController(title: "Success!", message: "Your spot at \(self.spotAddress!) has been posted.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action) in
                self.resetFields()
            }))
            self.present(alert, animated: true, completion: nil)
        }
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
    
    func dismissPicker() {
        view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func checkIfUserCanRegisterSpot() -> Bool {
        if spotLatitude == nil || spotLongitude == nil || spotAddress == nil || spotCity == nil {
            errorLabel.text = "Please select a valid address"
            return false
        } else if spotAvailableDays == [0,0,0,0,0,0,0] {
            errorLabel.text = "Please select at least one available day"
            return false
        } else if spotAvailableFrom == nil || spotAvailableTo == nil {
            errorLabel.text = "Please select a start and end time for your spot"
            return false
        } else if spotAvailableFrom! > spotAvailableTo! {
            errorLabel.text = "Availability start time must be earlier than end time"
            return false
        } else if spotAvailableTo! - spotAvailableFrom! < 60 {
            errorLabel.text = "Spot must be available for at least 1 hour"
            return false
        }
        return true
    }
    
    func resetFields() {
        self.addressFieldButton.setTitle("Search your space", for: .normal)
        for day in arrayOfDays {
            day.backgroundColor = UIColor.white
            day.setTitleColor( UIColor(hexString: "555555")!, for: .normal)
        }
        self.fromTimeSlotField.text = nil
        self.toTimeSlotField.text = nil
        self.priceSlider.value = 1.50
        
        spotLatitude = nil
        spotLongitude = nil
        spotAddress = nil
        spotCity = nil
        spotAvailableDays = [0,0,0,0,0,0,0]
        spotAvailableFrom = nil
        spotAvailableTo = nil
        spotHourlyPrice = nil
    }
    
    func setupProperties() {
        priceSlider.minimumValue = 0.50
        priceSlider.maximumValue = 4.00
        priceSlider.value = 1.50
        spotHourlyPrice = Double(priceSlider.value)
        errorLabel.text = nil
        arrayOfDays = [mondayButton, tuesdayButton, wednesdayButton, thursdayButton, fridayButton, saturdayButton, sundayButton]
    }
    
    fileprivate func setupUIElements() {
        self.navigationController?.setStatusBarStyle(.lightContent)
        registerSpotButton.layer.cornerRadius = 6
        addressFieldButton.layer.borderWidth = 1
        addressFieldButton.layer.borderColor = UIColor.darkGray.cgColor
        
        for day in arrayOfDays {
            day.layer.cornerRadius = 4
            day.layer.borderWidth = 1
            day.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
}

//MARK: Extensions
extension HostViewController {
    //MARK: Google Places autcomplete delegate methods
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
    //MARK: PickerView Toolbar Setup
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
