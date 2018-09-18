//
//  EditProfileTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 17/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD

class EditProfileTableViewController: UITableViewController {

    // MARK: Connection With UI
    
    @IBOutlet weak var saveButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet var avatarImageTappedGestureRecogniser: UITapGestureRecognizer!
    var avatarImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        setupUI()
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    // MARK: IBAction
    @IBAction func saveButtonPressed(_ sender: Any) {
        if firstNameTextField.text != "" && lastNameTextField.text != "" && emailTextField.text != "" {
            ProgressHUD.show("Saving")
            // Block Save Buton
            saveButtonOutlet.isEnabled = false
            
            let fullName = firstNameTextField.text! + " " + lastNameTextField.text!
            
            var withValues = [kFIRSTNAME : firstNameTextField.text!, kLASTNAME : lastNameTextField.text!, kFULLNAME : fullName]
            
            if avatarImage != nil {
                let avatarData = avatarImage!.jpegData(compressionQuality: 0.7)!
                let avatarString = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                withValues[kAVATAR] = avatarString
                
            }
            // Update Current User
            updateCurrentUserInFirestore(withValues: withValues) { (error) in
                if error != nil {
                    DispatchQueue.main.async {
                        ProgressHUD.showError(error?.localizedDescription)
                        print("couldnot update user" + (error?.localizedDescription)!)
                    }
                    self.saveButtonOutlet.isEnabled = true

                    return
                }
                ProgressHUD.showSuccess("Saved")
                self.saveButtonOutlet.isEnabled = true
                
                self.navigationController?.popViewController(animated: true)
            }
        }else{
            ProgressHUD.showError("All Fields are required")
        }
    }
    
    
    @IBAction func avatarTapped(_ sender: Any) {
        print("Show Image Picker")
    }
    // MARK: Set Up UI
    func setupUI(){
        let currentUser = FUser.currentUser()!
        avatarImageView.isUserInteractionEnabled = true
        
        firstNameTextField.text = currentUser.firstname
        lastNameTextField.text = currentUser.lastname
        emailTextField.text = currentUser.email
        
        if currentUser.avatar != ""{
            imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
   
}
