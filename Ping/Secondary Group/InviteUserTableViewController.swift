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
import Contacts

class InviteUserTableViewController: UITableViewController, UserTableViewCellDelegate, UISearchResultsUpdating {
    var users: [FUser] = []
    var newMembersId : [String] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    var currentMembersId: [String] = []
    var group: NSDictionary!
    var matchedUsers: [FUser] = []
    var filteredMatchedUsers: [FUser] = []
    var countryCode: String?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    lazy var contacts: [CNContact] = {
        
        let contactStore = CNContactStore()
        
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey] as [Any]

        var allContainers: [CNContainer] = []
        
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try     contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
                print("container result.........\(containerResults)")
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }()
    


    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Members"
        tableView.tableFooterView = UIView()
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonPressed))]
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            // Fallback on earlier versions
        }
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        currentMembersId = group[kMEMBERS] as! [String]
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadUsers()
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return self.allUsersGrouped.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredMatchedUsers.count
        } else {
            // find section title
            let sectionTitle = self.sectionTitleList[section]
            
            // find users for given section title
            let users = self.allUsersGrouped[sectionTitle]
            
            // return count for users
            return users!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        
        cell.delegate = self
        cell.generateCellWith(fuser: user, indexPath: indexPath)
        
        return cell
}
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return self.sectionTitleList[section]
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return self.sectionTitleList
        }
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
    
    func loadUsers(){
        ProgressHUD.show()
        reference(.User).order(by: kFIRSTNAME, descending: false).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                ProgressHUD.dismiss()
                return
            }
            if !snapshot.isEmpty {
                self.matchedUsers = []
                self.users.removeAll()
                
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fuser = FUser.init(_dictionary: userDictionary)
                    
                    if fuser.objectId != FUser.currentId(){
                        self.users.append(fuser)
                    }
                }
                ProgressHUD.dismiss()
                self.tableView.reloadData()
            }
            ProgressHUD.dismiss()
            self.compareUsers()
        }
    }
    
    func compareUsers() {
        
        for user in users {
            
            if user.phoneNumber != "" {
                countryCode = user.countryCode
                let contact = searchForContactUsingPhoneNumber(phoneNumber1: user.phoneNumber)
                
                //if we have a match, we add to our array to display them
                if contact.count > 0 {
                    matchedUsers.append(user)
                }
                
                self.tableView.reloadData()
                
            }
        }
        //                updateInformationLabel()
        
        self.splitDataInToSection()
    }
    
    //MARK: Contacts
    
    func searchForContactUsingPhoneNumber(phoneNumber1: String) -> [CNContact] {
        
        var result: [CNContact] = []
        
        //go through all contacts
        for contact in self.contacts {
            
            if !contact.phoneNumbers.isEmpty {
                
                
                //go through every number of each contac
                for phoneNumber in contact.phoneNumbers {
                    
                    let fulMobNumVar  = phoneNumber.value
                    
                    
                    let phoneNumber = fulMobNumVar.value(forKey: "digits") as? String
                    
                    
                    let phoneNumberWithCountryCode = countryCode! + phoneNumber1
                    
                    //compare phoneNumber of contact with given user's phone number
                    if phoneNumber == phoneNumber1 || phoneNumber == phoneNumberWithCountryCode {
                        
                        result.append(contact)
                    }
                    
                }
            }
        }
        
        return result
    }
    
    // MARK: IBAction
    

    
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
    fileprivate func splitDataInToSection() {
        
        // set section title "" at initial
        var sectionTitle: String = ""
        
        // iterate all records from array
        for i in 0..<self.matchedUsers.count {
            
            // get current record
            let currentUser = self.matchedUsers[i]
            
            // find first character from current record
            let firstChar = currentUser.firstname.uppercased().first!
            
            // convert first character into string
            let firstCharString = "\(firstChar)"
            
            // if first character not match with past section title then create new section
            if firstCharString != sectionTitle {
                
                // set new title for section
                sectionTitle = firstCharString
                
                // add new section having key as section title and value as empty array of string
                self.allUsersGrouped[sectionTitle] = []
                
                // append title within section title list
                if !sectionTitleList.contains(sectionTitle){
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            
            // add record to the section
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
        tableView.reloadData()
    }
    // MARK: Search Controller functions
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filteredContentForSearchText(searchText: String, scope: String = "All"){
        filteredMatchedUsers = matchedUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
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
