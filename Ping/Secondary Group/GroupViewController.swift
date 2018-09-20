//
//  GroupViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 20/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class GroupViewController: UIViewController, ImagePickerDelegate {
 
    

    // MARK: IB Outlets
    @IBOutlet weak var cameraButtonOutlet: UIImageView!
    @IBOutlet weak var groupNameTextFiled: UITextField!
    @IBOutlet weak var editButtonOutlet: UIButton!
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    
    // MARK: Variables
    var group: NSDictionary!
    var groupIcon: UIImage?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cameraButtonOutlet.isUserInteractionEnabled = true
        cameraButtonOutlet.addGestureRecognizer(iconTapGesture)
        
        setupUI()
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Invite Users", style: .plain, target: self, action: #selector(self.inviteUsers))]
    }
    

    // MARK: IBAction
    
    @IBAction func cameraIconTapped(_ sender: Any) {
        showIconOption()
    }
    @IBAction func editButtonPressed(_ sender: Any) {
        showIconOption()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        var withValues  : [String: Any]
        if groupNameTextFiled.text != "" {
            withValues = [kNAME : groupNameTextFiled.text]
            
        }else{
            ProgressHUD.showError("Group Name is Required")
            return
        }
        let avatarData = cameraButtonOutlet.image?.jpegData(compressionQuality: 0.4)!
        let avatarString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        withValues = [kNAME : groupNameTextFiled.text!, kAVATAR : avatarString!]
        
        Group.updateGroup(groupId: group?[kGROUPID] as! String, withValues:  withValues)
        
        withValues = [kWITHUSERUSERNAME : groupNameTextFiled.text!, kAVATAR: avatarString!]
        
        updateExistingRicentWithNewValues(chatRoomId: group[kGROUPID] as! String, members: group[kMEMBERS] as! [String], withValues: withValues)
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func inviteUsers(){
        let userVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inviteUserTableView") as! InviteUserTableViewController
        userVC.group = group
        self.navigationController?.pushViewController(userVC, animated: true)
    }
    
    //MARK: Helpers
    func setupUI(){
        self.title = "Group"
        groupNameTextFiled.text = group[kNAME] as? String
        imageFromData(pictureData: group[kAVATAR] as! String) { (avatarImage) in
            if avatarImage != nil {
                self.cameraButtonOutlet.image = avatarImage!.circleMasked
            }
        }
        
    }
    
    func showIconOption(){
        let optionMenu = UIAlertController(title: "Choose Group Icon", message: nil, preferredStyle: .actionSheet)
        
        let takePhotoAction = UIAlertAction(title: "Take/Choose Photo", style: .default) { (alert) in
            let imagePicker = ImagePickerController()
            imagePicker.delegate = self
            imagePicker.imageLimit = 1
            self.present(imagePicker, animated: true, completion: nil)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in

        }
        if groupIcon != nil {
            let resetAction = UIAlertAction(title: "Reset", style: .default) { (alert) in
                self.groupIcon = nil
                self.cameraButtonOutlet.image = UIImage(named: "cameraIcon")
                self.editButtonOutlet.isHidden = true
            }
            optionMenu.addAction(resetAction)
        }
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverpresentationController = optionMenu.popoverPresentationController {
                currentPopoverpresentationController.sourceView = editButtonOutlet
                currentPopoverpresentationController.sourceRect = editButtonOutlet.bounds
                
                currentPopoverpresentationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else {
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    // MARK: ImagePicker Delegate
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)

    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            self.groupIcon = images.first!
            self.cameraButtonOutlet.image = self.groupIcon!.circleMasked
            self.editButtonOutlet.isHidden = false
            
        }
        self.dismiss(animated: true, completion: nil)

    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }

    }
    

