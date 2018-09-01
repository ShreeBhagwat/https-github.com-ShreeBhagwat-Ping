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


class UsersTableViewController: UITableViewController, UISearchResultsUpdating {
   
    

    @IBOutlet weak var userSegment: UISegmentedControl!
    @IBOutlet weak var headerView: UIView!
    var allUsers: [FUser] = []
    var filteredUser: [FUser] = []
    var usersGrouped = NSDictionary() as! [String: [FUser]]
    var sectionTitle: [String] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUsers(filter: kCITY)
  
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        cell.generateCellWith(fuser: allUsers[indexPath.row], indexPath: indexPath)
        return cell
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
            self.sectionTitle = []
            self.usersGrouped = [:]
            
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
            }
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
    //Mark:- Search Controller Function
    
    func filterContentForSearch(searchText: String, scope: String = "All"){
        filteredUser = allUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearch(searchText: searchController.searchBar.text!)
    }
    

    

}
