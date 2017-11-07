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

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSAutocompleteViewControllerDelegate, GMSMapViewDelegate  {

    @IBOutlet weak var navBarButton: UIButton!
    @IBOutlet weak var searchBarButton: UIButton!
    @IBOutlet weak var locateButton: UIButton!
    
    @IBOutlet weak var gMapView: GMSMapView!
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Call sidemenu on load
        
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
        
        self.view.addSubview(gMapView)
        self.view.bringSubview(toFront: searchBarButton)
        self.view.bringSubview(toFront: locateButton)
        
        setupUIElements()
        loadMarkersFromDB()
    }
    
    func setupUIElements() {
        locateButton.tintColor = UIColor.white
        
        self.searchBarButton.layer.cornerRadius = 8
        self.searchBarButton.layer.borderWidth = 1
        self.searchBarButton.layer.borderColor = UIColor.white.cgColor
        
        self.locateButton.layer.cornerRadius = 8
        self.locateButton.layer.borderWidth = 1
        self.locateButton.layer.borderColor = UIColor.white.cgColor
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkIfUserIsLoggedIn()
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

    @IBAction func searchBarTapped(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        let filter = GMSAutocompleteFilter()
        filter.country = "CA"
        autocompleteController.delegate = self
        autocompleteController.autocompleteFilter = filter
        present(autocompleteController, animated: true, completion: nil)
    }

    @IBAction func locateButtonTapped(_ sender: UIButton) {
        handleLogout()
    }
    
    func loadMarkersFromDB() {
        let ref = FIRDatabase.database().reference().child("spots")
        ref.observe(.childAdded, with: { (snapshot) in
            if snapshot.value as? [String : AnyObject] != nil {
                self.gMapView.clear()
                guard let spot = snapshot.value as? [String : AnyObject] else {
                    return
                }
                
                let latitude = spot["latitude"]
                let longitude = spot["longitude"]
                let address = spot["address"]
                let rate = spot["rate"]
                
                DispatchQueue.main.async(execute: {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: latitude as! CLLocationDegrees, longitude: longitude as! CLLocationDegrees)
                    marker.title = address as? String
                    marker.snippet = "$\(String(format:"%.02f", (rate as? Float)!))/hr"
                    marker.icon = self.resizeImage(image: UIImage.init(named: "ParkSpaceLogo")!, newWidth: 30)
                    marker.map = self.gMapView
                    marker.userData = spot
                })
            }
        }, withCancel: nil)
    }

    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        let data = marker.userData! as? NSDictionary
        print("info: \(data!["address"]!)")
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
        let center = CLLocationCoordinate2D(latitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude)
        
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

