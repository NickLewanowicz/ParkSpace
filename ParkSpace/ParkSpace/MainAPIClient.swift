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
                //success
            }
        }, withCancel: nil)
    }
}
