//
//  PhoneAuthViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 23/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import ProgressHUD


class PhoneAuthViewController: UIViewController {

    
    
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var mobilePhoneTextField: UITextField!
    @IBOutlet weak var requestButtonOutlet: UIButton!
    
    var phoneNumber: String!
    var verificationId: String?
    
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

        countryCodeTextField.text = CountryCode().currentCode
    }
    

    @IBAction func requestButtonPressed(_ sender: Any) {
//        if verificationId != nil {
//            return
//        }
        if mobilePhoneTextField.text != "" && countryCodeTextField.text != "" {
            let fullNumber = countryCodeTextField.text! + mobilePhoneTextField.text!
            phoneNumber = fullNumber
  
            let alert = UIAlertController(title: "Phone Number", message: "Is This Your Phone Number \(fullNumber)", preferredStyle: .alert)
            
            let action = UIAlertAction(title: "Yes", style: .default) { (UIAlertAction) in
                PhoneAuthProvider.provider().verifyPhoneNumber(self.phoneNumber, uiDelegate: nil) { (verificationId, error) in
                    if error != nil {
                        ProgressHUD.showError(error!.localizedDescription)
                        return
                    }else {
                        self.verificationId = verificationId
                         self.performSegue(withIdentifier: "goToPhoneVerification", sender: self)
                    }
                    
                }
               
                
                
            }
            let cancel = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alert.addAction(action)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            return
            

        }else {
            ProgressHUD.showError("Phone Number Invalide")
            
        }
    }
    
    
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPhoneVerification" {
            let vc = segue.destination as! VerificationViewController
            vc.phoneNumber1 = phoneNumber
            vc.verificationId = verificationId
            vc.countryCode = countryCodeTextField.text
            vc.phoneNumberWithOutCountryCode = mobilePhoneTextField.text
            
        }
    }
    
    
}
    


