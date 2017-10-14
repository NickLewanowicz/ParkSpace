//
//  LoginRegisterViewController.swift
//  ParkSpace
//
//  Created by Mat Schmid on 2017-09-08.
//  Copyright © 2017 Mat Schmid. All rights reserved.
//

import UIKit
import ChameleonFramework
import M13Checkbox
import TextFieldEffects

import Firebase

class LoginRegisterViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var signInSelected: UIView!
    @IBOutlet weak var signUpSelected: UIView!
    
    var registerMode   : Bool = true
    var passwordsMatch : Bool = false
    
    var mapController : MapViewController?
    
    //MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.frame = UIScreen.main.bounds
        
        setupUIComponents()
    }
    
    //MARK: UI Setup Methods
    func setupUIComponents() {
        let topColor = UIColor(hexString: "6375FF")
        let bottomColor = UIColor(hexString: "5C3280")
        
        backgroundView.backgroundColor = UIColor(gradientStyle: UIGradientStyle.topToBottom, withFrame: self.backgroundView.frame, andColors: [topColor!, bottomColor!])
        
        registerButton.layer.cornerRadius = 14
        signInSelected.isHidden = true
        passwordCheckmark.isHidden = true
        confirmPasswordCheckmark.isHidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        addScreenElementsAndCallSetupMethods()
        
        confirmPasswordTextField.addTarget(self, action: #selector(comparePasswordTextfieldValues), for: UIControlEvents.editingChanged)
        passwordTextField.addTarget(self, action: #selector(comparePasswordTextfieldValues), for: UIControlEvents.editingChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func addScreenElementsAndCallSetupMethods() {
        self.view.addSubview(nameTextField)
        self.view.addSubview(emailTextField)
        self.view.addSubview(passwordTextField)
        self.view.addSubview(confirmPasswordTextField)
        self.view.addSubview(checkbox)
        self.view.addSubview(termsText)
        self.view.addSubview(termsBtn)
        self.view.addSubview(passwordCheckmark)
        self.view.addSubview(confirmPasswordCheckmark)
        self.view.addSubview(errorLabel)
        
        setupNameTextField()
        setupEmailTextField()
        setupPasswordTextField()
        setupConfirmPasswordTextField()
        setupCheckbox()
        setupTermsText()
        setupTermsBtn()
        setupPasswordCheckmark()
        setupConfirmPasswordCheckmark()
        setupErrorLabel()
    }
    
    func comparePasswordTextfieldValues(){
        if passwordTextField.text! == confirmPasswordTextField.text! && passwordTextField.text != "" && confirmPasswordTextField.text != "" && (passwordTextField.text?.characters.count)! >= 6 {
            self.passwordsMatch = true
            passwordCheckmark.isHidden = false
            confirmPasswordCheckmark.isHidden = false
            self.errorLabel.text = ""
        } else {
            self.passwordsMatch = false
            passwordCheckmark.isHidden = true
            confirmPasswordCheckmark.isHidden = true
        }
    }
    
    func checkIfUserCanRegister() -> Bool {
        if nameTextField.text != nil &&
            emailTextField.text != nil &&
            passwordTextField.text != nil &&
            confirmPasswordTextField.text != nil &&
            passwordsMatch {
            return true
        } else {
            return false
        }
    }
    
    func register() {
        if (passwordTextField.text?.characters.count)! < 6 {
            self.errorLabel.text = "Password must be at least 6 characters"
            return
        }
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text
            else {
                errorLabel.text = "Missing mandatory field(s)"
                return
        }
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
            if error != nil {
                self.errorLabel.text = "Invalid form entry"
                print(error.debugDescription)
                return
            }
            guard let uid = user?.uid else {
                self.errorLabel.text = "Authentication failed"
                return
            }
            
            //Auth succesful
            let values = ["name": name, "email": email]
            self.completeRegistrationWithUser(uid: uid, values: values as [String : AnyObject])
        })
    }
    
    private func completeRegistrationWithUser(uid: String, values: [String : AnyObject]){
        let ref = FIRDatabase.database().reference(fromURL: "https://parkspace-ios.firebaseio.com/")
        let userRef = ref.child("users").child(uid)
        
        userRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error.debugDescription)
                self.errorLabel.text = "Network error"
                return
            }
            //self.mapController?.nameLabel.text = values["name"] as? String
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func login() {
        guard let email = emailTextField.text, let password = passwordTextField.text
            else {
                errorLabel.text = "Missing mandatory field(s)"
                return
        }
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user: FIRUser?, loginErr) in
            if loginErr != nil {
                self.errorLabel.text = "Invalid email or password"
                return
            }
            self.mapController?.setupComponents()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil  {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y = 0
            }
        }
    }
    
    //MARK: Event Handlers
    @IBAction func signInBtnTapped(_ sender: UIButton) {
        if (registerMode) {
            
            self.registerButton.setTitle("Sign in", for: .normal)
            
            self.signUpBtn.setTitleColor(UIColor(hexString: "95989A"), for: .normal)
            self.signInBtn.setTitleColor(UIColor(hexString: "FFFFFF"), for: .normal)
            self.signInSelected.isHidden = false
            self.signUpSelected.isHidden = true
            
            self.nameTextField.isHidden = true
            self.confirmPasswordTextField.isHidden = true
            self.checkbox.isHidden = true
            self.termsText.isHidden = true
            
            self.termsBtn.setTitle("Forgot password?", for: .normal)
            
            self.nameTextField.text = ""
            self.emailTextField.text = ""
            self.passwordTextField.text = ""
            self.confirmPasswordTextField.text = ""
            self.passwordCheckmark.isHidden = true
            self.confirmPasswordCheckmark.isHidden = true
            registerMode = false
        }
    }
    
    @IBAction func signUpBtnTapped(_ sender: UIButton) {
        if (!registerMode) {
            
            self.registerButton.setTitle("Register", for: .normal)
            
            self.signUpBtn.setTitleColor(UIColor(hexString: "FFFFFF"), for: .normal)
            self.signInBtn.setTitleColor(UIColor(hexString: "95989A"), for: .normal)
            self.signInSelected.isHidden = true
            self.signUpSelected.isHidden = false
            
            self.nameTextField.isHidden = false
            self.confirmPasswordTextField.isHidden = false
            self.checkbox.isHidden = false
            self.termsText.isHidden = false
            
            self.termsBtn.setTitle("Terms of Service", for: .normal)
            
            self.nameTextField.text = ""
            self.emailTextField.text = ""
            self.passwordTextField.text = ""
            self.confirmPasswordTextField.text = ""
            self.passwordCheckmark.isHidden = true
            self.confirmPasswordCheckmark.isHidden = true
            
            registerMode = true
        }
    }
    
    @IBAction func loginRegisterBtnTapped(_ sender: Any) {
        if registerMode {
            if checkIfUserCanRegister() {
                register()
            } else {
                errorLabel.text = "Missing mandatory field(s)"
            }
        } else {
            login()
        }
    }
    
    //MARK: UI Elements
    let nameTextField : HoshiTextField = {
        let txt = HoshiTextField()
        txt.placeholder = "FULL NAME"
        txt.autocorrectionType = .no
        txt.autocapitalizationType = .words
        txt.placeholderLabel.font = UIFont(name: "HelveticaNeue", size: 18)
        txt.placeholderColor = UIColor(hexString: "FFFFFF")!
        txt.borderInactiveColor = UIColor(hexString: "95989A")!
        txt.borderActiveColor = UIColor(hexString: "19E698")!
        txt.textColor = UIColor(hexString: "95989A")!
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    let emailTextField : HoshiTextField = {
        let txt = HoshiTextField()
        txt.placeholder = "EMAIL"
        txt.placeholderLabel.font = UIFont(name: "HelveticaNeue", size: 18)
        txt.autocapitalizationType = .none
        txt.autocorrectionType = .no
        txt.keyboardType = .emailAddress
        txt.placeholderColor = UIColor(hexString: "FFFFFF")!
        txt.borderInactiveColor = UIColor(hexString: "95989A")!
        txt.borderActiveColor = UIColor(hexString: "19E698")!
        txt.textColor = UIColor(hexString: "95989A")!
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    let passwordTextField : HoshiTextField = {
        let txt = HoshiTextField()
        txt.placeholder = "PASSWORD"
        txt.placeholderLabel.font = UIFont(name: "HelveticaNeue", size: 18)
        txt.autocapitalizationType = .none
        txt.isSecureTextEntry = true
        txt.placeholderColor = UIColor(hexString: "FFFFFF")!
        txt.borderInactiveColor = UIColor(hexString: "95989A")!
        txt.borderActiveColor = UIColor(hexString: "19E698")!
        txt.textColor = UIColor(hexString: "95989A")!
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    let confirmPasswordTextField : HoshiTextField = {
        let txt = HoshiTextField()
        txt.placeholder = "CONFIRM PASSWORD"
        txt.placeholderLabel.font = UIFont(name: "HelveticaNeue", size: 18)
        txt.autocapitalizationType = .none
        txt.isSecureTextEntry = true
        txt.placeholderColor = UIColor(hexString: "FFFFFF")!
        txt.borderInactiveColor = UIColor(hexString: "95989A")!
        txt.borderActiveColor = UIColor(hexString: "19E698")!
        txt.textColor = UIColor(hexString: "95989A")!
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    let checkbox : M13Checkbox = {
        let box = M13Checkbox()
        box.boxType = .square
        box.tintColor = UIColor(hexString: "19E698")!
        box.secondaryTintColor = UIColor(hexString: "FFFFFF")!
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }()
    
    let termsText : UILabel = {
        let txt = UILabel()
        txt.text = "I agree with all the statements in"
        txt.font = UIFont(name: "HelveticaNeue", size: 14)
        txt.textColor = UIColor(hexString: "95989A")!
        txt.translatesAutoresizingMaskIntoConstraints = false
        return txt
    }()
    
    let termsBtn : UIButton = {
        let btn = UIButton()
        btn.setTitle("Terms of Service", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 15)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    let passwordCheckmark : UIImageView = {
        let img = UIImageView()
        img.image = UIImage(named: "Checkmark")
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    let confirmPasswordCheckmark : UIImageView = {
        let img = UIImageView()
        img.image = UIImage(named: "Checkmark")
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    let errorLabel : UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont(name: "HelveticaNeue", size: 14)
        lbl.textColor = UIColor(hexString: "EC5D57")!
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    //MARK: Setup Methods
    func setupNameTextField() {
        self.nameTextField.topAnchor.constraint(equalTo: self.signUpSelected.bottomAnchor, constant: 25.5).isActive = true
        self.nameTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.nameTextField.widthAnchor.constraint(equalToConstant: 254).isActive = true
        self.nameTextField.heightAnchor.constraint(equalToConstant: 65).isActive = true
    }
    
    func setupEmailTextField() {
        self.emailTextField.topAnchor.constraint(equalTo: self.nameTextField.bottomAnchor, constant: -5.5).isActive = true
        self.emailTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.emailTextField.widthAnchor.constraint(equalToConstant: 254).isActive = true
        self.emailTextField.heightAnchor.constraint(equalToConstant: 65).isActive = true
    }
    
    func setupPasswordTextField() {
        self.passwordTextField.topAnchor.constraint(equalTo: self.emailTextField.bottomAnchor, constant: -5.5).isActive = true
        self.passwordTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.passwordTextField.widthAnchor.constraint(equalToConstant: 254).isActive = true
        self.passwordTextField.heightAnchor.constraint(equalToConstant: 65).isActive = true
    }
    
    func setupConfirmPasswordTextField() {
        self.confirmPasswordTextField.topAnchor.constraint(equalTo: self.passwordTextField.bottomAnchor, constant: -5.5).isActive = true
        self.confirmPasswordTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.confirmPasswordTextField.widthAnchor.constraint(equalToConstant: 254).isActive = true
        self.confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 65).isActive = true
    }
    
    func setupCheckbox() {
        self.checkbox.bottomAnchor.constraint(equalTo: self.registerButton.topAnchor, constant: -58).isActive = true
        self.checkbox.leftAnchor.constraint(equalTo: self.registerButton.leftAnchor).isActive = true
        self.checkbox.widthAnchor.constraint(equalToConstant: 20).isActive = true
        self.checkbox.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    func setupTermsText() {
        self.termsText.centerYAnchor.constraint(equalTo: self.checkbox.centerYAnchor).isActive = true
        self.termsText.rightAnchor.constraint(equalTo: self.registerButton.rightAnchor, constant: 10).isActive = true
        self.termsText.widthAnchor.constraint(equalToConstant: 220).isActive = true
        self.termsText.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    func setupTermsBtn() {
        self.termsBtn.topAnchor.constraint(equalTo: self.termsText.bottomAnchor, constant: 5).isActive = true
        self.termsBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.termsBtn.widthAnchor.constraint(equalToConstant: 150).isActive = true
        self.termsBtn.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    func setupPasswordCheckmark() {
        self.passwordCheckmark.centerYAnchor.constraint(equalTo: self.passwordTextField.centerYAnchor, constant: 10).isActive = true
        self.passwordCheckmark.rightAnchor.constraint(equalTo: self.passwordTextField.rightAnchor).isActive = true
        self.passwordCheckmark.widthAnchor.constraint(equalToConstant: 10.95).isActive = true
        self.passwordCheckmark.heightAnchor.constraint(equalToConstant: 8.21).isActive = true
    }
    
    func setupConfirmPasswordCheckmark() {
        self.confirmPasswordCheckmark.centerYAnchor.constraint(equalTo: self.confirmPasswordTextField.centerYAnchor, constant: 10).isActive = true
        self.confirmPasswordCheckmark.rightAnchor.constraint(equalTo: self.confirmPasswordTextField.rightAnchor).isActive = true
        self.confirmPasswordCheckmark.widthAnchor.constraint(equalToConstant: 10.95).isActive = true
        self.confirmPasswordCheckmark.heightAnchor.constraint(equalToConstant: 8.21).isActive = true
    }
    
    func setupErrorLabel() {
        self.errorLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.errorLabel.bottomAnchor.constraint(equalTo: self.termsText.topAnchor, constant: -8).isActive = true
        self.errorLabel.widthAnchor.constraint(equalTo: self.registerButton.widthAnchor).isActive = true
        self.errorLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
}
