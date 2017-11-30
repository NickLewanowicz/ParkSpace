//
//  ViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-09-07.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import GooglePlaces
import ChameleonFramework

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSAutocompleteViewControllerDelegate, GMSMapViewDelegate, MapMarkerDelegate, RentViewControllerDelegate  {
    //MARK: Properties
    @IBOutlet weak var searchBarButton: UIButton!
    @IBOutlet weak var gMapView: GMSMapView!
    
    let locationManager = CLLocationManager()
    private var infoWindow = MapMarkerWindow()
    fileprivate var locationMarker : GMSMarker? = GMSMarker()
    
    //MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkIfUserIsLoggedIn()
        self.navigationController?.isNavigationBarHidden = true
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                gMapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        gMapView.isMyLocationEnabled = true
        gMapView.settings.myLocationButton = true
        gMapView.delegate = self
        
        infoWindow = loadNiB()
        
        self.view.addSubview(gMapView)
        self.view.bringSubview(toFront: searchBarButton)
        
        setupUIElements()
        loadMarkersFromDB()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        checkIfUserIsLoggedIn()
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    //MARK: Setup Methods
    func setupUIElements() {
        
        self.searchBarButton.layer.cornerRadius = 8
        self.searchBarButton.layer.borderWidth = 1
        self.searchBarButton.layer.borderColor = UIColor.white.cgColor
    }

    func checkIfUserIsLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }
    }
    
    func handleLogout() {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginRegisterViewController = LoginRegisterViewController()
        loginRegisterViewController.mapController = self
        present(loginRegisterViewController, animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
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
    
    //MARK: Event Markers
    @IBAction func searchBarTapped(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        let filter = GMSAutocompleteFilter()
        filter.country = "CA"
        autocompleteController.delegate = self
        autocompleteController.autocompleteFilter = filter
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func didTapInfoButton(data: NSDictionary) {
        let rentViewController = self.storyboard?.instantiateViewController(withIdentifier: "RentViewController") as! RentViewController
        rentViewController.spotData = data
        rentViewController.delegate = self
        self.navigationController?.pushViewController(rentViewController, animated: true)
    }
    
    //MARK: Firebase Handlers
    func loadMarkersFromDB() {
        let ref = FIRDatabase.database().reference().child("spots")
        ref.observe(.childAdded, with: { (snapshot) in
            if snapshot.value as? [String : AnyObject] != nil {
                //self.gMapView.clear()
                guard var spot = snapshot.value as? [String : AnyObject] else {
                    return
                }
                spot["spotID"] = snapshot.key as AnyObject
                
                let latitude = spot["latitude"]
                let longitude = spot["longitude"]
                var rented : Bool
                if let rent = spot["spotRented"] {
                    rented = (rent as? Bool)!
                } else {
                    rented = false
                }
                
                DispatchQueue.main.async(execute: {
                    let marker = GMSMarker()
                    
                    let markerImage = self.resizeImage(image: UIImage.init(named: "ParkSpaceLogo")!, newWidth: 30).withRenderingMode(.alwaysTemplate)
                    let markerView = UIImageView(image: markerImage)
                    markerView.tintColor = rented ? .lightGray : UIColor(hexString: "19E698")
                    marker.iconView = markerView
                    marker.position = CLLocationCoordinate2D(latitude: latitude as! CLLocationDegrees, longitude: longitude as! CLLocationDegrees)
                    marker.icon = self.resizeImage(image: UIImage.init(named: "ParkSpaceLogo")!, newWidth: 30)
                    marker.map = self.gMapView
                    marker.userData = spot
                })
            }
        }, withCancel: nil)
    }
    
    //MARK: GMSMapViewDelegate Methods
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        var markerData : NSDictionary?
        if let data = marker.userData! as? NSDictionary {
            markerData = data
        }
        print(self.gMapView.camera.target.latitude)
        locationMarker = marker
        infoWindow.removeFromSuperview()
        infoWindow = loadNiB()
        guard let location = locationMarker?.position else {
            print("locationMarker is nil")
            return false
        }
        infoWindow.spotData = markerData
        infoWindow.delegate = self
        infoWindow.alpha = 0.9
        infoWindow.layer.cornerRadius = 12
        infoWindow.layer.borderWidth = 2
        infoWindow.layer.borderColor = UIColor(hexString: "19E698")?.cgColor
        infoWindow.infoButton.layer.cornerRadius = infoWindow.infoButton.frame.height / 2
        
        let address = markerData!["address"]!
        let rate = markerData!["rate"]!
        let fromTime = markerData!["fromTime"]!
        let toTime = markerData!["toTime"]!
        
        var rented : Bool
        if let rent = markerData!["spotRented"] {
            rented = (rent as? Bool)!
        } else {
            rented = false
        }
        
        if rented {
            infoWindow.infoButton.backgroundColor = UIColor.lightGray
            infoWindow.infoButton.isEnabled = false
        }

        infoWindow.addressLabel.text = address as? String
        infoWindow.priceLabel.text = "$\(String(format:"%.02f", (rate as? Float)!))/hr"
        infoWindow.availibilityLabel.text = "\(convertMinutesToTime(minutes: (fromTime as? Int)!)) - \(convertMinutesToTime(minutes: (toTime as? Int)!))"
        infoWindow.center = mapView.projection.point(for: location)
        infoWindow.center.y = infoWindow.center.y - 82
        self.view.addSubview(infoWindow)
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if (locationMarker != nil){
            guard let location = locationMarker?.position else {
                print("locationMarker is nil")
                return
            }
            infoWindow.center = mapView.projection.point(for: location)
            infoWindow.center.y = infoWindow.center.y - 82
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        infoWindow.removeFromSuperview()
    }
    
    func loadNiB() -> MapMarkerWindow {
        let infoWindow = MapMarkerWindow.instanceFromNib() as! MapMarkerWindow
        return infoWindow
    }
    
    func didRentSpot(id: String) {
        let ref = FIRDatabase.database().reference().child("spots").child(id)
        let values = ["spotRented": true]
        ref.updateChildValues(values)
        loadMarkersFromDB()
    }
    
    func didHostSpot() {
        loadMarkersFromDB()
    }
}

extension MapViewController {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
        gMapView.isMyLocationEnabled = true
        gMapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude, zoom: 16);
        self.gMapView.camera = camera
        self.gMapView.isMyLocationEnabled = true
        
        locationManager.stopUpdatingLocation()
    }
}

extension MapViewController {
    //Handle the users selection
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.searchBarButton.setTitle(place.name, for: .normal)
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15);
        self.gMapView.camera = camera
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

