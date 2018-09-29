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

class GroupViewController: UIViewController, ImagePickerDelegate, UITableViewDelegate, UITableViewDataSource {
 
    

    // MARK: IB Outlets
    @IBOutlet weak var cameraButtonOutlet: UIImageView!
    @IBOutlet weak var groupNameTextFiled: UITextField!
    @IBOutlet weak var editButtonOutlet: UIButton!
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    
 
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var participantsLabelOutlet: UILabel!
    // MARK: Variables
    var group: NSDictionary!
    var group1: NSDictionary!
    var groupIcon: UIImage?
    var currentUserId = FUser.currentId()
    var ownerId: String!
    var admin: [String]? = []
    var memberIds : [String] = []
    var allMembers : [FUser] = []
    var groupId: String?
    var membersToPush: [String] = []
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        cameraButtonOutlet.isUserInteractionEnabled = true
        cameraButtonOutlet.addGestureRecognizer(iconTapGesture)
        setupUI()
        getUsersOfGroup()
        getGroupInfo()
        tableView.delegate = self
        tableView.dataSource = self

        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Invite Users", style: .plain, target: self, action: #selector(self.inviteUsers))]
    }

    
    
    // Get Users from firebase
    func getUsersOfGroup(){
        getUsersFromFirestore(withIds: memberIds) { (memberuser) in
            self.allMembers = memberuser
            self.allMembers.append(FUser.currentUser()!)
            self.updateParticipantsLabel()
            self.tableView.reloadData()
        }
        
    }
    func getGroupInfo(){
        reference(.Group).document(groupId!).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else {return}
            if snapshot.exists {
                let userDictionary = snapshot.data()
                self.ownerId = (snapshot.data()!["ownerID"] as! String)
                self.admin = snapshot.data()!["adminsId"] as! [String]
                self.membersToPush = snapshot.data()!["membersToPush"] as! [String]
            }
        }
    }
    
    
    // MARK: TableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath) as! GroupInfoTableViewCell
    
        
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
    
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if currentUserId == allMembers[indexPath.row].objectId{ // Selecting self <------------------
            
             tableView.deselectRow(at: indexPath, animated: true)
            let alert = UIAlertController(title: allMembers[indexPath.row].firstname + " (Self)", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Leave Group", style: .default, handler: { _ in
                
                let currentUser = self.allMembers[indexPath.row].objectId
                self.leaveGroup(currentId: currentUser)
                
                sendPushNotification(memberToPush: self.membersToPush, message: self.allMembers[indexPath.row].firstname + " Has Left The Group")
                self.allMembers.remove(at: indexPath.row)
                self.updateParticipantsLabel()
                self.tableView.reloadData()
                
                self.navigationController?.popToRootViewController(animated: true)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else if allMembers[indexPath.row].objectId == ownerId { // Selecting Owner <---------------
            let alert = UIAlertController(title: allMembers[indexPath.row].firstname + " (Creater)", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Info", style: .default, handler: { _ in
                //self.sendToInfoView()
                print("info Button Pressed")
                let selectUser = self.allMembers[indexPath.row]
                self.presentUserProfile(forUser: selectUser)
            }))
            alert.addAction(UIAlertAction(title: "Send Message", style: .default, handler: { _ in
                print("Send Message Pressed")
            }))
            alert.addAction(UIAlertAction(title: "Call User", style: .default, handler: { _ in
                print("Call User Pressed")
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if currentUserId != ownerId && (admin!.contains(allMembers[indexPath.row].objectId)){ // Selecting Other admin <---------------
            
            let alert = UIAlertController(title: allMembers[indexPath.row].firstname + "(Admin)", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Info", style: .default, handler: { _ in
                //self.sendToInfoView()
                print("info Button Pressed")
                let selectUser = self.allMembers[indexPath.row]
                self.presentUserProfile(forUser: selectUser)
            }))
            alert.addAction(UIAlertAction(title: "Send Message", style: .default, handler: { _ in
                print("Send Message Pressed")
            }))
            alert.addAction(UIAlertAction(title: "Call User", style: .default, handler: { _ in
                print("Call User Pressed")
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: allMembers[indexPath.row].firstname, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Info", style: .default, handler: { _ in
                //self.sendToInfoView()
                print("info Button Pressed")
                let selectUser = self.allMembers[indexPath.row]
                self.presentUserProfile(forUser: selectUser)
            }))
            alert.addAction(UIAlertAction(title: "Send Message", style: .default, handler: { _ in
                print("Send Message Pressed")
            }))
            alert.addAction(UIAlertAction(title: "Call User", style: .default, handler: { _ in
                print("Call User Pressed")
            }))
          
            ///////
            if currentUserId == ownerId || admin!.contains(currentUserId){
                
                alert.addAction(UIAlertAction(title: "Make Admin", style: .default, handler: { _ in
                    print("Make admin Pressed")
                    
                    let adminId = self.allMembers[indexPath.row].objectId
                    if (self.admin!.contains(adminId)){
                        ProgressHUD.showError("User Is admin Already")
                    } else {
                        self.admin?.append(adminId)
                        let withValues = [kADMINID: self.admin]
                        Group.updateGroup(groupId: self.groupId!, withValues: withValues as [String : Any])
                        ProgressHUD.showSuccess()
                    }
                    
                    }))
                
                alert.addAction(UIAlertAction(title: "Remove User", style: .default, handler: { _ in
                    print("Remove User Pressed")
                    let removeUserId = self.allMembers[indexPath.row].objectId
                    self.removeUsers(removeUserId: removeUserId)
                    self.allMembers.remove(at: indexPath.row)
                    self.updateParticipantsLabel()
                    self.tableView.reloadData()
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        tableView.reloadData()
    
    }
    // MARK: Alert Action Functions
    func presentUserProfile(forUser: FUser){
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        profileVC.user = forUser
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func leaveGroup(currentId: String){
        if currentId == FUser.currentId() {
            let memberIndex = memberIds.index(of: currentId)
            memberIds.remove(at: memberIndex!)
            if membersToPush.contains(currentId){
            let membersToPushIndex = membersToPush.index(of: currentId)
            membersToPush.remove(at: membersToPushIndex!)
            }
            if (admin?.contains(currentId))! {
                let adminIndex = admin?.index(of: currentId)
                admin?.remove(at: adminIndex!)
            }
            let withValues = [kMEMBERS: memberIds, kMEMBERSTOPUSH: membersToPush, kADMINID: admin]
            Group.updateGroup(groupId: groupId!, withValues: withValues)
            updateExistingRicentWithNewValues(chatRoomId: groupId!, members: memberIds, withValues: withValues)
            
        }
    }
    
    
    func removeUsers(removeUserId: String){
        let memberIndex = memberIds.index(of: removeUserId)
        memberIds.remove(at: memberIndex!)
        if membersToPush.contains(removeUserId){
            let membersToPushIndex = membersToPush.index(of: removeUserId)
            membersToPush.remove(at: membersToPushIndex!)
        }
        if (admin?.contains(removeUserId))! {
            let adminIndex = admin?.index(of: removeUserId)
            admin?.remove(at: adminIndex!)
        }
        let withValues = [kMEMBERS: memberIds, kMEMBERSTOPUSH: membersToPush]
        Group.updateGroup(groupId: groupId!, withValues: withValues)
        updateExistingRicentWithNewValues(chatRoomId: groupId!, members: memberIds, withValues: withValues)
        
    }
    // MARK: GroupCell Delegate
 
    
    func updateParticipantsLabel(){
        participantsLabelOutlet.text = "Participants: \(self.allMembers.count)"
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
    

