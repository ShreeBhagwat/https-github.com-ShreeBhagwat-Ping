//
//  FinishRegistrationViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 31/08/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class FinishRegistrationViewController: UIViewController, ImagePickerDelegate {
  
    

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var countryTextFiled: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
   
    @IBOutlet weak var phoneNumberTextLabelOutlet: UILabel!
    
    var email: String!
    var password: String!
    var avatarImage: UIImage?
    var phoneNumber2: String!
    var countryCodeText: String!
    var phoneNumberWithoutCountryCode: String!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppUtility.lockOrientation(.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppUtility.lockOrientation(.all)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "4")
        backgroundImage.contentMode = UIView.ContentMode.scaleAspectFill
        self.view.insertSubview(backgroundImage, at: 0)
        
        phoneNumberTextLabelOutlet.text = phoneNumberWithoutCountryCode
        
        
    avatarImageView.isUserInteractionEnabled = true
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
        
        if nameTextField.text != "" && lastNameTextField.text != "" && countryTextFiled.text != "" && cityTextField.text != "" {
            
//            FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: lastNameTextField.text!) { (error) in
//                if error != nil {
//                    ProgressHUD.dismiss()
//                    ProgressHUD.showError(error?.localizedDescription)
//                }
//                self.registerUser()
//
//            }
            self.registerUser()
            
        }else{
            ProgressHUD.showError("All Fields are Compulsary")
        }
    }
    
    @IBAction func avatarImageTapped(_ sender: Any) {
        print("Avatar Image Picker")
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        
        present(imagePickerController, animated: true, completion: nil)
        dismissKeyboard()
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
        phoneNumberTextLabelOutlet.text = ""
    }
    
    
    func registerUser(){
        let fullName = nameTextField.text! + " " + lastNameTextField.text!
        var tempDictionary : Dictionary = [kFIRSTNAME: nameTextField.text!,
                                           kLASTNAME: lastNameTextField.text!,
                                           kFULLNAME: fullName,
                                           kCOUNTRY: countryTextFiled.text!,
                                           kCITY: cityTextField.text!,
                                           kCOUNTRYCODE: countryCodeText!,
                                           kPHONE: phoneNumberTextLabelOutlet.text!] as [String : Any]
        
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
    
    // MARK: Image Picker Delegate
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage?.circleMasked
        }
         self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
         self.dismiss(animated: true, completion: nil)
    }
    
}
