//
//  RegisterSpotViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-07.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import Photos
import Firebase
import FirebaseStorage
import RSKPlaceholderTextView

class RegisterSpotViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var descriptionTextView: RSKPlaceholderTextView!
    @IBOutlet weak var spotImage: UIImageView!
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    //MARK: Spot Properties
    var spotLatitude : Double? = nil
    var spotLongitude: Double? = nil
    var spotAddress  : String? = nil
    var spotCity     : String? = nil
    var spotAvailableDays : [Int] = [0,0,0,0,0,0,0] //monday -> [0], sunday -> [6]
    var spotAvailableFrom : Int? = nil //minutes since the start of day
    var spotAvailableTo   : Int? = nil //minutes since the start of day, > spotAvailableFrom
    var spotHourlyPrice   : Double? = nil //Hourly rate in CAD
    
    var spotDescription : String? = nil
    
    //MARK: Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIElements()
    }
    
    //MARK: Setup functions
    fileprivate func setupUIElements() {
        addressLabel.text = spotAddress!
        
        descriptionTextView.layer.borderWidth = 1
        selectImageButton.layer.cornerRadius = 6
        registerButton.layer.cornerRadius = 6
        
        spotImage.tag = 1
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: Event Handlers
    @IBAction func selectImageButtonTapped(_ sender: UIButton) {
        checkPermission()
        let picker = UIImagePickerController()
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func registerSpotButtonTapped(_ sender: UIButton) {
        if descriptionTextView.text == "" {
            self.spotDescription = "No description provided"
        } else {
            self.spotDescription = descriptionTextView.text
        }
        uploadImage() { url in
            if url != nil {
                self.registerSpot(url!)
            } else {
                let alert = UIAlertController(title: "Error", message: "Failed to register spot. Image likely failed to post", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay.", style: .default, handler: nil))
            }
        }
    }
    
    //MARK: Firebase Handlers
    func uploadImage(completion: @escaping (_ url: String?) -> Void) {
        let imageID = NSUUID().uuidString
        let storageRef = FIRStorage.storage().reference().child("spot_images").child("\(imageID).jpg")
        if let uploadData = UIImageJPEGRepresentation(self.spotImage.image!, 0.1) {
            storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(error ?? "error")
                    completion(nil)
                }
                if let imageURL = metadata?.downloadURL()?.absoluteString {
                    completion(imageURL)
                }
            })
        }
    }
    
    func registerSpot(_ imageURL: String) {
        let ref = FIRDatabase.database().reference().child("spots")
        let childRef = ref.childByAutoId()
        let userID = FIRAuth.auth()?.currentUser?.uid
        let timestamp = Int(NSDate.timeIntervalSinceReferenceDate)
        let values = ["userID": userID!, "address": spotAddress!, "city": spotCity!, "latitude": spotLatitude!, "longitude": spotLongitude!, "availableDays": spotAvailableDays, "fromTime": spotAvailableFrom!, "toTime": spotAvailableTo!, "rate": spotHourlyPrice!, "timestamp": timestamp, "description": spotDescription!, "imageURL": imageURL] as [String : Any]
        
        childRef.updateChildValues(values) { (err, ref) in
            if err != nil {
                print(err.debugDescription)
                return
            }
            self.saveSpotToUser(childRef.key)
        }
    }
    
    func saveSpotToUser(_ spotID: String) {
        let userID = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference().child("users").child(userID!).child("managedSpots")
        let values = [spotID: 1]
        ref.updateChildValues(values) { (error, ref) in
            if error != nil {
                return
            }
            //Success
            let alert = UIAlertController(title: "Success!", message: "Your spot at \(self.spotAddress!) has been posted.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action) in
                _ = self.navigationController?.popToRootViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    //MARK: ImagePicker Delegate Methods
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImage : UIImage?
        if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            selectedImage = originalImage
        }
        
        if let image = selectedImage {
            spotImage.tag = 2
            spotImage.image = image
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access is granted by user")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("success")
                }
            })
            print("It is not determined until now")
        case .restricted:
            // same same
            print("User do not have access to photo album.")
        case .denied:
            // same same
            print("User has denied the permission.")
        }
    }
}
