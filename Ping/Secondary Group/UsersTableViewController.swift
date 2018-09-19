//
//  UsersTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 01/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD


class UsersTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {
    
    
   
    
    @IBOutlet weak var userSegment: UISegmentedControl!
    @IBOutlet weak var headerView: UIView!
    var allUsers: [FUser] = []
    var filteredUser: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitleList: [String] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        loadUsers(filter: kCITY)
  
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return allUsersGrouped.count
        }
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUser.count
        } else {
            //Find Section Tile
            let sectionTitle = self.sectionTitleList[section]
            // user for given title
            let users = self.allUsersGrouped[sectionTitle]
          return users!.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUser[indexPath.row]
        }else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        
        
        cell.generateCellWith(fuser: user, indexPath: indexPath)
        cell.delegate = self
        return cell
    }
    
    //MARK: TableView Delegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        }else {
            return sectionTitleList[section]
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
        
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUser[indexPath.row]
        }else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        if !checkBlockedStatus(withUser: user) {
            let chatVC = ChatsViewController()
            chatVC.title = user.firstname
            chatVC.membersToPush = [FUser.currentId(), user.objectId]
            chatVC.membersId = [FUser.currentId(), user.objectId]
            chatVC.chatroomId = startPrivateChat(user1: FUser.currentUser()!, user2: user)
            chatVC.isGroup = false
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
            
        }else{
            ProgressHUD.showError("This User Is Not Available For Chat")
        }
        
        
    }
   
    
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
    //MARK:- IBActions
    
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
    
    //MARK: Search Controller Function
    
    func filterContentForSearch(searchText: String, scope: String = "All"){
        filteredUser = allUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearch(searchText: searchController.searchBar.text!)
    }
    

    //MARK: Helper Function
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
    // MARK: UserTableViewCellDelegate
    func didTappedAvatarImage(indexPath: IndexPath) {
        print("User table view avatar pressed\(indexPath)")
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        
        var user: FUser
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUser[indexPath.row]
        }else {
            let sectionTitle = self.sectionTitleList[indexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![indexPath.row]
        }
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)
    }

}
