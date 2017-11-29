//
//  MainAPIClient.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-21.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import Firebase
import Stripe

protocol MainAPIDelegate: class {
    func didFailToLoadEphKey(fail : Bool)
}

class MainAPIClient: NSObject, STPEphemeralKeyProvider {
    weak var delegate : MainAPIDelegate?
    static let shared = MainAPIClient()
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference().child("users").child(uid!)
        let values = ["api_version": apiVersion]
        ref.child("stripe").updateChildValues(values)

        ref.observe(.childAdded, with: { (snapshot) in
            if snapshot.hasChild("ephemeral_key") {
                ref.child("stripe").child("ephemeral_key").observeSingleEvent(of: .value, with: { (snapkey) in
                    guard let json = snapkey.value as? [String : AnyObject] else {
                        return
                    }
                    self.delegate?.didFailToLoadEphKey(fail: false)
                    completion(json, nil)
                }, withCancel: nil)
            } else {
                self.delegate?.didFailToLoadEphKey(fail: true)
            }
        }, withCancel: nil)
    }
    
    func updateAPIVersion() {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference().child("users").child(uid!)
        ref.observe(.childAdded, with: { (snapshot) in
            if snapshot.hasChild("api_version") {
                ref.child("stripe").child("api_version").removeValue()
            }
        }, withCancel: nil)
    }
    
    func createCharge(source: String, amount: Int, completion: @escaping (NSError?) -> Void) {
        let randomUID = NSUUID().uuidString
        let userUID = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference().child("users").child(userUID!).child("stripe").child("charges").child(randomUID)
        let values = ["source": source, "amount": amount] as [String : Any]
        ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print("error")
            }
            completion(nil)
        })
    }
}
