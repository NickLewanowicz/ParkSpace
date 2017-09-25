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

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSAutocompleteViewControllerDelegate, SWRevealViewControllerDelegate {

    @IBOutlet weak var navBarButton: UIButton!
    @IBOutlet weak var searchBarButton: UIButton!
    @IBOutlet weak var locateButton: UIButton!
    
    @IBOutlet weak var gMapView: GMSMapView!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.revealViewController().delegate = self
        
        // Call sidemenu on load
        sideMenus()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        gMapView.isMyLocationEnabled = true
        
        self.view.addSubview(gMapView)
        self.view.bringSubview(toFront: navBarButton)
        self.view.bringSubview(toFront: searchBarButton)
        self.view.bringSubview(toFront: locateButton)
        
        setupUIElements()
    }
    
    func setupUIElements() {
        self.navBarButton.layer.cornerRadius = 8
        self.navBarButton.layer.borderWidth = 1
        self.navBarButton.layer.borderColor = UIColor.gray.cgColor
        
        self.searchBarButton.layer.cornerRadius = 8
        self.searchBarButton.layer.borderWidth = 1
        self.searchBarButton.layer.borderColor = UIColor.gray.cgColor
        
        self.locateButton.layer.cornerRadius = 8
        self.locateButton.layer.borderWidth = 1
        self.locateButton.layer.borderColor = UIColor.gray.cgColor
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkIfUserIsLoggedIn()
    }
    
    func checkIfUserIsLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            setupComponents()
        }
    }
    
    func setupComponents() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).observe(.value, with: { (snapshot) in
            if let dict = snapshot.value as? [String : AnyObject] {
                //self.nameLabel.text = dict["name"] as? String
                print("\(String(describing: dict["name"] as? String))")
            }
        })
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

    @IBAction func searchBarTapped(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    func sideMenus() {
        if revealViewController() != nil {
            navBarButton.addTarget(revealViewController, action: #selector(SWRevealViewController.revealToggle(_:)), for: .touchUpInside)
            revealViewController().rearViewRevealWidth = 275
            revealViewController().rightViewRevealWidth = 160
        }
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
        
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude, zoom: 15);
        self.gMapView.camera = camera
        self.gMapView.isMyLocationEnabled = true
        
        let marker = GMSMarker(position: center)
        
        print("Latitude :- \(userLocation!.coordinate.latitude)")
        print("Longitude :-\(userLocation!.coordinate.longitude)")
        marker.map = self.gMapView
        
        marker.title = "Current Location"
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

