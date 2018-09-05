//
//  ProfileViewTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 03/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

class ProfileViewTableViewController: UITableViewController {

    
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!

    @IBOutlet weak var messageButton: UIButton!
    
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var blockUserButton: UIButton!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var user : FUser?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
   
    }
    
    // MARK: - IBAction Function
    
    @IBAction func callButtonPressed(_ sender: Any) {
        print("Call user button pressed \(user?.fullname)")
    }
    
    @IBAction func messageButtonPressed(_ sender: Any) {
        print("chat user button pressed \(user?.fullname)")
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

}
