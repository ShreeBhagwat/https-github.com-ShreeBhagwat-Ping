//
//  VerificationViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 23/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import FirebaseAuth
import ProgressHUD

class VerificationViewController: UIViewController {
    @IBOutlet weak var noticeLabelOutlet: UILabel!
    
    @IBOutlet weak var verificationCodeTextFiled: UITextField!
    
    @IBOutlet weak var submitButtonOutlet: UIButton!
    
    var phoneNumber1: String!
    var verificationId: String?
    var countryCode: String?
    var phoneNumberWithOutCountryCode: String?
    
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
        print("View did load \(verificationId)")
        noticeLabelOutlet.text = "We have sent a 6 digit Verification Code via SMS To \(phoneNumber1!). Check your phone and enter the code below"
//         let defaults =  UserDefaults.standard
//        verificationId = defaults.string(forKey: "authVerificationID")!
    }
    
    

    @IBAction func submitButtonPressed(_ sender: Any) {
        registerUser()
    }
    
    func registerUser() {
        if verificationCodeTextFiled.text != ""{
            ProgressHUD.show()
            let defaults = UserDefaults.standard
            let verification = defaults.object(forKey: "authVerificationID")
            FUser.registerUserWith(phoneNumber: phoneNumber1, verificationCode: verificationCodeTextFiled.text!, verificationId: verification as! String) { (error, shouldLogin) in
                
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError("Error in Verirification \(error!.localizedDescription)")
                    print("Error in Verirification \(error?.localizedDescription)")
                    return
                }
                if shouldLogin {
                    // GoTo App
                    self.goToApp()
                }else {
                    ProgressHUD.show()
                    self.performSegue(withIdentifier: "pGoToRegistrationScreen", sender: self)
                    ProgressHUD.dismiss()
                }
            }
        }else {
            ProgressHUD.showError("Error Please Varification Code")
        }
        
    }
    
    func goToApp(){
        ProgressHUD.dismiss()
 
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pGoToRegistrationScreen" {
            let vc = segue.destination as! FinishRegistrationViewController
            vc.phoneNumber2 = phoneNumber1
            vc.countryCodeText = countryCode
            vc.phoneNumberWithoutCountryCode = phoneNumberWithOutCountryCode
            
        }
    }
    
}
