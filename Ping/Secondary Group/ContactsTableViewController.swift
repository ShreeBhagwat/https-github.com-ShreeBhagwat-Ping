//
//  ContactsTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 18/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import Contacts
import FirebaseFirestore
import ProgressHUD


class ContactsTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {

    var users: [FUser] = []
    var matchedUsers: [FUser] = []
    var filteredMatchedUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList: [String] = []
    var countryCode: String?
    var isGroup = false
    var memberIdsOfGroupChat: [String] = []
    var membersOfGroupChat: [FUser] = []

    let searchController = UISearchController(searchResultsController: nil)

    lazy var contacts: [CNContact] = {

        let contactStore = CNContactStore()

        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey] as [Any]

        // Get all the containers
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


    override func viewWillAppear(_ animated: Bool) {

        //to remove empty cell lines
        tableView.tableFooterView = UIView()
        
                loadUsers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Contacts"
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

                setupButtons()
        
    }

    //MARK: TableViewDataSource

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

        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") as! UserTableViewCell

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


    //MARK: TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let userToChat: FUser

        if searchController.isActive && searchController.searchBar.text != "" {
            userToChat = filteredMatchedUsers[indexPath.row]

        }else {
            let users = self.allUsersGrouped[sectionTitle]
            userToChat = users![indexPath.row]
        }
        if !isGroup {
            // 1 on 1 chat
            if checkBlockedStatus(withUser: userToChat){
            ProgressHUD.showError("This User is not Available For chat")
            } else {

                let chatVC = ChatsViewController()
                chatVC.titleName = userToChat.firstname
                chatVC.membersId = [FUser.currentId(), userToChat.objectId]
                chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]

                chatVC.chatroomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
                chatVC.isGroup = false
                chatVC.hidesBottomBarWhenPushed = true

                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        }else{
            // group chat
            // Blue CheckMark
            if let cell =  tableView.cellForRow(at: indexPath){
                if cell.accessoryType == .checkmark{
                    cell.accessoryType = .none
                }else{
                    cell.accessoryType = .checkmark
                }
            }
            // add and remove feom the array
            let selected = memberIdsOfGroupChat.contains(userToChat.objectId)
            if selected{
                let objectIndex = memberIdsOfGroupChat.index(of: userToChat.objectId)
                memberIdsOfGroupChat.remove(at: objectIndex!)
                membersOfGroupChat.remove(at: objectIndex!)
            }else{
                memberIdsOfGroupChat.append(userToChat.objectId)
                membersOfGroupChat.append(userToChat)
            }
            self.navigationItem.rightBarButtonItem?.isEnabled = memberIdsOfGroupChat.count > 0
        }

    }

    // MARK: IB Actions

    @objc func inviteButtonPressed(){
        let text = "Hey ping me on this new app\(kAPPURL)"
        let objectsToShare: [Any] = [text]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.setValue("Lets Chat On Ping", forKey: "subject")
        self.present(activityViewController, animated: true, completion: nil)
    }

    @objc func searchNearByButtonPressed(){
        let userVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userTableView") as! UsersTableViewController

        self.navigationController?.pushViewController(userVC, animated: true)
    }

    @objc func nextButtonPressed(){
        let newGroupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newGroupView") as! NewGroupViewController

        newGroupVC.memberIds = memberIdsOfGroupChat
        newGroupVC.allMembers = membersOfGroupChat
        self.navigationController?.pushViewController(newGroupVC, animated: true)
    }

    // MARK: LOAD USERS
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
////////////// The Following code not in Use. But have been kept for Reference and Logic

//    func updatePhoneNumber(phoneNumber: String, replacePlusSign: Bool) -> String {
//
//        if replacePlusSign {
//            return phoneNumber.replacingOccurrences(of: "+", with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
//
//        } else {
//            return phoneNumber.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
//        }
//    }
//
//
//    func removeCountryCode(countryCodeLetters: String, fullPhoneNumber: String) -> String {
//
//        let countryCode = CountryCode()
//
//        let countryCodeToRemove = countryCode.codeDictionaryShort[countryCodeLetters.uppercased()]
//
//        //remove + from country code
//        let updatedCode = updatePhoneNumber(phoneNumber: countryCodeToRemove!, replacePlusSign: true)
//
//        //remove countryCode
//        let replacedNUmber = fullPhoneNumber.replacingOccurrences(of: updatedCode, with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
//
//
//                print("Code \(countryCodeLetters)")
//                print("full number \(fullPhoneNumber)")
//                print("code to remove \(updatedCode)")
//                print("clean number is \(replacedNUmber)")
//
//        return replacedNUmber
//    }

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


    // MARK: User TableView Cell delegate
    func didTappedAvatarImage(indexPath: IndexPath) {
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        var user : FUser!
        if searchController.isActive && searchController.searchBar.text != ""{
            user = filteredMatchedUsers[indexPath.row]
        }else {
            let sectionTile = self.sectionTitleList[indexPath.row]
            let users = self.allUsersGrouped[sectionTile]
            user = users![indexPath.row]
        }

        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)

    }

    // MARK: Helper Function

    func setupButtons(){
        if isGroup {
            // For group Chat
            let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(self.nextButtonPressed))
            self.navigationItem.rightBarButtonItem = nextButton
            self.navigationItem.rightBarButtonItems!.first?.isEnabled = false

        }else {
            // For 1 on 1 chat
            let inviteButton = UIBarButtonItem(image: UIImage(named: "invite"), style: .plain, target: self, action: #selector(self.inviteButtonPressed))
            inviteButton.tintColor = UIColor.white
            let searchButton = UIBarButtonItem(image: UIImage(named: "nearMe"), style: .plain, target: self, action: #selector(self.searchNearByButtonPressed))
            self.navigationItem.rightBarButtonItems = [inviteButton]
        }
    }




}


