//
//  BlockedUserViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 16/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD

class BlockedUserViewController: UIViewController , UITableViewDataSource, UITableViewDelegate, UserTableViewCellDelegate{

    

    @IBOutlet weak var notificationLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    var blockedUserArray : [FUser] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        loadUsers()
        
    }
    
    // MARK: Table View DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        notificationLabel.isHidden = blockedUserArray.count != 0
        if blockedUserArray.count != 0 {
            notificationLabel.isHidden = true
        }else {
            notificationLabel.isHidden = false
            notificationLabel.text = "No Blocked User"
        }
        return blockedUserArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        cell.delegate = self
        cell.generateCellWith(fuser: blockedUserArray[indexPath.row], indexPath: indexPath)
        return cell
    }
    
    // Mark: Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Unblock"
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var tempblockedUser = FUser.currentUser()!.blockedUsers
        let userIdToUnblock = blockedUserArray[indexPath.row].objectId
        
        tempblockedUser.remove(at: tempblockedUser.index(of: userIdToUnblock)!)
        blockedUserArray.remove(at: indexPath.row)
        
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID: tempblockedUser]) { (error) in
            if error != nil {
                ProgressHUD.showError("Unable To Unblock User Please Try again Later\(error?.localizedDescription)")
            }
            self.tableView.reloadData()
        }
    }
    
    // MARK Header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Swipe Left To Unblock"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    // MARK: LOAD BLOCK USERS
    func loadUsers(){
        if FUser.currentUser()!.blockedUsers.count > 0 {
            ProgressHUD.show()
            
            getUsersFromFirestore(withIds: FUser.currentUser()!.blockedUsers) { (allBlockedUsers) in
                ProgressHUD.dismiss()
                self.blockedUserArray = allBlockedUsers
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: User tableView cell Delegate
    func didTappedAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        profileVC.user = blockedUserArray[indexPath.row]
        self.navigationController?.pushViewController(profileVC, animated: true)
    }


}
