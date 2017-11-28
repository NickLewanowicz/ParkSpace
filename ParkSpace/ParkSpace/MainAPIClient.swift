//
//  MainAPIClient.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-11-21.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import Firebase
import Stripe

class MainAPIClient: NSObject, STPEphemeralKeyProvider {
    static let shared = MainAPIClient()
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference().child("users").child(uid!).child("stripe")
        let values = ["api_version": apiVersion]
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild("api_version") {
                ref.child("api_version").removeValue()
            }
            ref.updateChildValues(values) { (error, ref) in
                if error != nil {
                    print("error")
                }
            }
        }, withCancel: nil)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild("ephemeral_key") {
                ref.child("ephemeral_key").observeSingleEvent(of: .value, with: { (snapkey) in
                    guard let json = snapkey.value as? [String : AnyObject] else {
                        return
                    }
                    completion(json, nil)
                }, withCancel: { (err) in
                    completion(nil, nil)
                })
                
            }
        }, withCancel: nil)
        
    }
    
    func createCharge(source: String, amount: Int, completion: @escaping (NSError?) -> Void) {
        let randomUID = NSUUID().uuidString
        let userUID = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference().child("users").child(userUID!).child("stripe").child("charges").child(randomUID)
        let values = ["source": source,
                      "amount": amount] as [String : Any]
        ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print("error")
            }
            completion(nil)
        })
    }
}
