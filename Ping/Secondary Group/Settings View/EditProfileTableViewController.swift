//
//  EditProfileTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 17/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class EditProfileTableViewController: UITableViewController, ImagePickerDelegate {
 
    

    // MARK: Connection With UI
    
    @IBOutlet weak var phoneNumberTextFiled: UITextField!
    @IBOutlet weak var saveButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var userBiotextView: UITextView!
    @IBOutlet var avatarImageTappedGestureRecogniser: UITapGestureRecognizer!
    var avatarImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        setupUI()
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    
    // MARK: IBAction
    @IBAction func saveButtonPressed(_ sender: Any) {
        if firstNameTextField.text != "" && lastNameTextField.text != "" && phoneNumberTextFiled.text != "" {
            ProgressHUD.show("Saving")
            // Block Save Buton
            saveButtonOutlet.isEnabled = false
            
            let fullName = firstNameTextField.text! + " " + lastNameTextField.text!
            let bio = userBiotextView.text!
            let phonenumber = phoneNumberTextFiled.text
            var withValues = [kFIRSTNAME : firstNameTextField.text!, kLASTNAME : lastNameTextField.text!, kFULLNAME : fullName, kBIO: bio, kPHONE: phonenumber]
            
            if avatarImage != nil {
                let avatarData = avatarImage!.jpegData(compressionQuality: 0.4)!
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
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        self.present(imagePickerController, animated: true, completion: nil )
    }
    // MARK: Set Up UI
    func setupUI(){
        let currentUser = FUser.currentUser()!
        avatarImageView.isUserInteractionEnabled = true
        
        firstNameTextField.text = currentUser.firstname
        lastNameTextField.text = currentUser.lastname
        userBiotextView.text = currentUser.bio
        phoneNumberTextFiled.text = currentUser.phoneNumber
        
        if currentUser.avatar != ""{
            imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    // MARK: ImagePicker Delegate
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage!.circleMasked
            
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    

    
 
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Edit Details"
        } else if section == 1 {
             return "Edit Bio"
        }else {
            return "Change Phone Number With Country Code"
        }
       
    }
}
