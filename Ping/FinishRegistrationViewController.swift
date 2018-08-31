//
//  FinishRegistrationViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 31/08/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD

class FinishRegistrationViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var countryTextFiled: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var phoneNumberTextFiled: UITextField!
    
    var email: String!
    var password: String!
    var avatarImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(email)
        print(password)
        // Do any additional setup after loading the view.
    }
    
    //MARK:- IBActions
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        cleanTextFields()
        dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func DoneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        ProgressHUD.show("Registering...")
        
        if nameTextField.text != "" && lastNameTextField.text != "" && countryTextFiled.text != "" && cityTextField.text != "" && phoneNumberTextFiled.text != "" {
            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: lastNameTextField.text!) { (error) in
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error?.localizedDescription)
                }
                self.registerUser()
                
            }
            
        }else{
            ProgressHUD.showError("All Fields are Compulsary")
        }
    }
    
    
    //Mark:- Helper
    func dismissKeyboard(){
        self.view.endEditing(false)
    }
    func cleanTextFields() {
        nameTextField.text = ""
        lastNameTextField.text = ""
        countryTextFiled.text = ""
        cityTextField.text = ""
        phoneNumberTextFiled.text = ""
    }
    
    
    func registerUser(){
        let fullName = nameTextField.text! + " " + lastNameTextField.text!
        var tempDictionary : Dictionary = [kFIRSTNAME: nameTextField.text!,
                                           kLASTNAME: lastNameTextField.text!,
                                           kFULLNAME: fullName,
                                           kCOUNTRY: countryTextFiled.text!,
                                           kCITY: cityTextField.text!,
                                           kPHONE: phoneNumberTextFiled.text!] as [String : Any]
        
        if avatarImage == nil {
            imageFromInitials(firstName: nameTextField.text!, lastName: lastNameTextField.text!) { (avatarInitials) in
                let avatarIMG = avatarInitials.jpegData(compressionQuality: 0.5)
                let avatar = avatarIMG!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                tempDictionary[kAVATAR] = avatar
                
                //finish avatar
                self.finishRegistration(withValue: tempDictionary)
            }
        } else {
            
            let avatarData = avatarImage?.jpegData(compressionQuality: 0.5)
            let avatar = avatarData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatar
            
            //Finish Registration
            self.finishRegistration(withValue: tempDictionary)
        }
    }
    
    
    func finishRegistration(withValue: [String : Any]){
        updateCurrentUserInFirestore(withValues: withValue) { (error) in
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                    print(error?.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
            self.goToApp()
        }
    }
    
    func goToApp(){
        cleanTextFields()
        dismissKeyboard()
        
         NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }
    
}
