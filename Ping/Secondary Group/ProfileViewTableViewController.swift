//
//  ProfileViewTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 03/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD

class ProfileViewTableViewController: UITableViewController {

    
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var blockUserButton: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var user : FUser?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
   
    }
    
    // MARK: - IBAction Function
    
    @IBAction func callButtonPressed(_ sender: Any) {
        
        // Call User
        callUser()
        
        let currentUser = FUser.currentUser()!
        let call = CallClass(_calledId: currentUser.objectId, _withUserId: user!.objectId, _callerFullName: currentUser.fullname, _withUserFullName: user!.fullname)
        
        call.saveCallInBackground()
        
    }
    
    @IBAction func messageButtonPressed(_ sender: Any) {
        if !checkBlockedStatus(withUser: user!) {
            let chatVC = ChatsViewController()
            chatVC.title = user!.firstname
            chatVC.membersToPush = [FUser.currentId(), user!.objectId]
            chatVC.membersId = [FUser.currentId(), user!.objectId]
            chatVC.chatroomId = startPrivateChat(user1: FUser.currentUser()!, user2: user!)
            chatVC.isGroup = false
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
            
        }else{
            ProgressHUD.showError("This User Is Not Available For Chat")
        }
    }
    
    @IBAction func blockUserButtonPressed(_ sender: Any) {
        var currentBlockedIds =  FUser.currentUser()!.blockedUsers
        if currentBlockedIds.contains(user!.objectId){
            let index = currentBlockedIds.index(of: user!.objectId)!
            currentBlockedIds.remove(at: index)
        } else {
            currentBlockedIds.append(user!.objectId)
        }
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID: currentBlockedIds]) { (error) in
            if error != nil {
                print("error updating user\(error?.localizedDescription)")
                return
            }
            self.updateBlockStatus()
        }
        blockUser(userToBlock: user!)
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }
    
    // MARK: Setup UI
    
    func setupUI(){
        if user != nil {
            self.title = "Profile"
            fullNameLabel.text = user?.fullname
            phoneNumberLabel.text = user?.phoneNumber
            
            // Block Status of user
            updateBlockStatus()
            
            imageFromData(pictureData: user!.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }

    func updateBlockStatus(){
        if user!.objectId != FUser.currentId() {
            blockUserButton.isHidden = false
            callButton.isHidden = false
            messageButton.isHidden = false
            
        } else {
            blockUserButton.isHidden = true
            callButton.isHidden = true
            messageButton.isHidden = true
        }
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId){
            blockUserButton.setTitle("Unblock User", for: .normal)
        }else {
            blockUserButton.setTitle("Block User", for: .normal)

        }
    }
    // MARK: Call User
    func callClient() -> SINCallClient {
        return appDelegate._client.call()
    }
    
    func callUser(){
        let userToCall = user!.objectId
        let call = callClient().callUser(withId: userToCall)
        
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
        
        callVC._call = call
        self.present(callVC, animated: true, completion: nil)

    }

}
