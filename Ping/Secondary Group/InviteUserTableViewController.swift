//
//  InviteUserTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 20/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

class InviteUserTableViewController: UITableViewController, UserTableViewCellDelegate {
   
    

    
    @IBOutlet weak var headerView: UIView!
    
    var allUsers: [FUser] = []
    var newMembersId : [String] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    var currentMembersId: [String] = []
    var group: NSDictionary!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Users"
        tableView.tableFooterView = UIView()
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonPressed))]
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        currentMembersId = group[kMEMBERS] as! [String]
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Load Function
        loadUsers(filter: kCITY)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return self.allUsersGrouped.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = self.sectionTitleList[section]
        let users = self.allUsersGrouped[sectionTitle]
        return users!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        
        var user: FUser
        
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]

        cell.generateCellWith(fuser: users![indexPath.row], indexPath: indexPath)
        cell.delegate = self
        return cell
}
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return sectionTitleList[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    
            return self.sectionTitleList
        
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let users = self.allUsersGrouped[sectionTitle]
        let selectedUser = users![indexPath.row]
        
        if currentMembersId.contains(selectedUser.objectId) {
            ProgressHUD.showError("User Already in Group")
            return
        }
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
            }else{
                cell.accessoryType = .checkmark
            }
        }
        // add/Rmove user from array
        let selected = newMembersId.contains(selectedUser.objectId)
        if selected{
            // Remove
            let objectIndex = newMembersId.index(of: selectedUser.objectId)!
            newMembersId.remove(at: objectIndex)
        }else{
            //add
            newMembersId.append(selectedUser.objectId)
            
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = newMembersId.count > 0
        
    }

    
    // MARK: LOAD Users
    
    func loadUsers(filter: String){
        ProgressHUD.show()
        
        var query: Query!
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        query.getDocuments { (snapshot, error) in
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGrouped = [:]
            
            if error != nil {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            guard let snapshot = snapshot else {
                ProgressHUD.dismiss()
                return
            }
            if !snapshot.isEmpty {
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as! NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    
                    if fUser.objectId != FUser.currentId() {
                        self.allUsers.append(fUser)
                    }
                }
                //Split to Groups
                self.splitDataIntoSections()
                self.tableView.reloadData()
            }
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
    // MARK: IBAction
    
    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default:
            return
        }
    }
    
    // MARK: UserTableViewCellDelegate
    func didTappedAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
        
        profileVC.user = users![indexPath.row]
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    @objc func doneButtonPressed(){
        updateGroup(group: group)
    }
    
    // MARK Helper Function
    fileprivate func splitDataIntoSections(){
        var sectionTitle: String = ""
        for i in 0..<self.allUsers.count {
            let currentUsers = self.allUsers[i]
            let firstChar = currentUsers.firstname.uppercased().first!
            let firstCharString = "\(firstChar)"
            
            if firstCharString != sectionTitle {
                
                sectionTitle = firstCharString.uppercased()
                self.allUsersGrouped[sectionTitle] = []
                
                if !sectionTitleList.contains(sectionTitle){
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            self.allUsersGrouped[firstCharString]?.append(currentUsers)
        }
    }
    
    func updateGroup(group: NSDictionary) {
        
        let tempMembers = currentMembersId + newMembersId
        let tempMembersToPush = group[kMEMBERSTOPUSH] as! [String] + newMembersId
        
        let withValues = [kMEMBERS : tempMembers, kMEMBERSTOPUSH : tempMembersToPush]
        
        Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)
        
        createRecentsForNewMembers(groupId: group[kGROUPID] as! String, groupName: group[kNAME] as! String, membersToPush: tempMembersToPush, avatar: group[kAVATAR] as! String)
        
        updateExistingRicentWithNewValues(chatRoomId: group[kGROUPID] as! String, members: tempMembers, withValues: withValues)
        
        goTogroupChat(membersToPush: tempMembersToPush, members: tempMembers)
        
    }
    
    func goTogroupChat(membersToPush: [String], members: [String]){
        let chatVC = ChatsViewController()
        chatVC.titleName = group[kNAME] as! String
        chatVC.membersId = members
        chatVC.membersToPush = membersToPush
        chatVC.chatroomId = group[kGROUPID] as! String
        chatVC.isGroup = true
        chatVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
}
