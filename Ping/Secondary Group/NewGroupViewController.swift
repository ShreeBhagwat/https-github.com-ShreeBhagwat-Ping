//
//  NewGroupViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 18/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class NewGroupViewController: UIViewController , UICollectionViewDelegate, UICollectionViewDataSource, GroupMemberCollectionViewCellDelegate, ImagePickerDelegate {
 
    
    // MARK: Connection Outlets
    
    @IBOutlet weak var editAvatarButton: UIButton!
    @IBOutlet weak var groupIconImageView: UIImageView!
    @IBOutlet weak var groupSubjectTextFiled: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var iconTappedGesture: UITapGestureRecognizer!
    
    // MARK: Variables
    var memberIds : [String] = []
    var allMembers : [FUser] = []
    var groupIcon : UIImage?
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        } else {
            // Fallback on earlier versions
        }
        groupIconImageView.isUserInteractionEnabled = true
        groupIconImageView.addGestureRecognizer(iconTappedGesture)
        updateParticipantsLabel()

    }
    
    // MARK: IBAction
    @objc func createButtonPressed(_ sender: Any){
        if groupSubjectTextFiled.text != "" {
                memberIds.append(FUser.currentId())
            let avatarData = UIImage(named: "groupIcon")!.jpegData(compressionQuality: 0.4)!
            var avatar = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            if groupIcon != nil {
                let avatarData = groupIcon!.jpegData(compressionQuality: 0.5)!
                avatar = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            }
            let groupId = UUID().uuidString
            // Create Group
            var adminsIds: [String] = []
            adminsIds.append(FUser.currentId())
            let group = Group(groupId: groupId, subject: groupSubjectTextFiled.text!, ownerId: FUser.currentId(), adminsId: adminsIds, members: memberIds, avatar: avatar)
            group.saveGroup()
            // Create Group Recent
            
            startGroupChat(group: group)
            
            
            // Go to Group Chat
            let chatVC = ChatsViewController()
            chatVC.title = group.groupDistionary[kNAME] as? String
            chatVC.membersId = group.groupDistionary[kMEMBERS] as! [String]
            chatVC.membersToPush = group.groupDistionary[kMEMBERS] as! [String]
            chatVC.chatroomId = groupId
            chatVC.groupOwnerId = FUser.currentId()
            chatVC.isGroup = true
            chatVC.hidesBottomBarWhenPushed = true
            
            self.navigationController?.pushViewController(chatVC, animated: true)
            
            
        }else{
            ProgressHUD.showError("Please Enter Group Subject")
        }
        
    }
    
    @IBAction func groupIconTapped(_ sender: Any) {
        showIconOption()
    }
    
    @IBAction func editIconButtonPressed(_ sender: Any) {
        showIconOption()
    }
    
    
    // MARK: CollectionView Data Source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! GroupMemberCollectionViewCell
        
        cell.delegate = self
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
        return cell
        
    }
    
    // MARK: GroupMemberCollectionViewDelegate
    
    func didClickDeleteButton(indexPath: IndexPath) {
        allMembers.remove(at: indexPath.row)
        memberIds.remove(at: indexPath.row)
        
        collectionView.reloadData()
        updateParticipantsLabel()
    }
    // MARK: Helper Function
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
                self.groupIconImageView.image = UIImage(named: "cameraIcon")
                self.editAvatarButton.isHidden = true
            }
            optionMenu.addAction(resetAction)
        }
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverpresentationController = optionMenu.popoverPresentationController {
                currentPopoverpresentationController.sourceView = editAvatarButton
                currentPopoverpresentationController.sourceRect = editAvatarButton.bounds
                
                currentPopoverpresentationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else {
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    func updateParticipantsLabel(){
        participantsLabel.text = "Participants: \(allMembers.count)"
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.createButtonPressed))]
        
        self.navigationItem.rightBarButtonItem?.isEnabled = allMembers.count > 0
    }
    
    // MARK: Image Picker Delegate
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true, completion: nil)

    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if images.count > 0 {
            self.groupIcon = images.first!
            self.groupIconImageView.image = self.groupIcon!.circleMasked
            self.editAvatarButton.isHidden = false
            
        }
        self.dismiss(animated: true, completion: nil)

    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }


}
