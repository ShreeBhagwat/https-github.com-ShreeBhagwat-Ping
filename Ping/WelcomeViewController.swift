//
//  WelcomeViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 30/08/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {

    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var email: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
      dismissKeyboard()
        
        if email.text != "" && password.text != "" {
            loginUser()
        }else {
            ProgressHUD.showError("Email and Password is Missing")
        }
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        dismissKeyboard()
        if email.text != "" && password.text != "" && confirmPassword.text != "" {
            if password.text == confirmPassword.text {
                  registerUser()
            } else {
                ProgressHUD.showError("Passwords Dosent Match")
            }
         
        }else {
            ProgressHUD.showError("All Fields are Required")
        }
    }
    @IBAction func backgroundTapped(_ sender: Any) {
        dismissKeyboard()
    }
    
    func dismissKeyboard(){
        self.view.endEditing(false)
    }
    func cleanTextFields() {
        email.text = ""
        password.text = ""
        confirmPassword.text = ""
    }
    
    func loginUser(){
        print("Login in")
        ProgressHUD.show("Login...")
        FUser.loginUserWith(email: email.text!, password: password.text!) { (error) in
            if error != nil {
                ProgressHUD.showError(error?.localizedDescription)
                return
            }
            self.goToApp()
        }
    }
    func registerUser(){
        print("REgistering in")
        performSegue(withIdentifier: "welcomeToFinishRegistration", sender: self)
        cleanTextFields()
        dismissKeyboard()
        
    }
    
    func goToApp(){
        ProgressHUD.dismiss()
        cleanTextFields()
        dismissKeyboard()
        
         NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        
    }
    
    //Mark: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "welcomeToFinishRegistration" {
            let vc = segue.destination as! FinishRegistrationViewController
            vc.email = email.text!
            vc.password = password.text
            
        }
    }
}
