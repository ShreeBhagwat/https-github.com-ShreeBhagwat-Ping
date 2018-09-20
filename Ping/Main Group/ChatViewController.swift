//
//  ChatViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 02/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import Foundation
import FirebaseFirestore

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentChatTableViewCellDelegate, UISearchResultsUpdating {
  
    
  let searchController = UISearchController(searchResultsController: nil)

    @IBOutlet weak var tableView: UITableView!
    var recentChats: [NSDictionary] = []
    var filteredChat: [NSDictionary] = []
    var recentListener: ListenerRegistration!
    
    
    override func viewWillAppear(_ animated: Bool) {
        loadRecentChats()
        tableView.tableFooterView = UIView()
        setTableViewController()
    }
    override func viewWillDisappear(_ animated: Bool) {
        recentListener.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController =  searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true

    }
    
    //Mark:- IBAction
    
    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        selectUserForChat(isGroup: false)
    }
    
    // MARK: Tableview delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredChat.count
        }else{
            return recentChats.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath) as! RecentChatTableViewCell
        var recent : NSDictionary
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChat[indexPath.row]
        }else{
            recent = recentChats[indexPath.row]
        }
        
        cell.generateCell(recentChat: recent, indexPath: indexPath)
        cell.delegate = self
        return cell
    }
    
    
    // MARK: TableViewDelegate function

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var tempRecent: NSDictionary!
     
        
        if searchController.isActive && searchController.searchBar.text != "" {
            tempRecent = filteredChat[indexPath.row]
        }else{
            tempRecent = recentChats[indexPath.row]
        }
        var muteTitle = "Unmute"
        var mute = false
        
        if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()){
            muteTitle = "Mute"
            mute = true
        }
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
           self.recentChats.remove(at: indexPath.row)
            deleteRecentChat(recentChatDictionary: tempRecent)
            self.tableView.reloadData()
        }
        
        let muteAction = UITableViewRowAction(style: .default, title: muteTitle) { (action, indexPath) in
            self.updatePushMembers(recent: tempRecent, mute: mute)
        }
        muteAction.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        
        return [deleteAction, muteAction]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Table View Selected at \(indexPath)")
        var recent : NSDictionary
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recent = filteredChat[indexPath.row]
        }else{
            recent = recentChats[indexPath.row]
        }
        // MARK: Restart Chat
        restartRecentChat(recent: recent)
        
        let chatsVC = ChatsViewController()
        chatsVC.hidesBottomBarWhenPushed = true
        chatsVC.titleName = (recent[kWITHUSERUSERNAME] as? String)!
        chatsVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
        chatsVC.membersId = (recent[kMEMBERS] as? [String])!
        chatsVC.chatroomId = (recent[kCHATROOMID] as? String)!
        chatsVC.isGroup = (recent[kTYPE] as! String) == kGROUP
      
        
        navigationController?.pushViewController(chatsVC, animated: true)
        // MARK: Show Chat View
    }
    
    // MARK: Load Recent Chats.
    
//    func loadRecentChats(){
//        recentListner = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener { (snapshot, error) in
//            guard let snapshot = snapshot else {return}
//            self.recentChats = []
//            if !snapshot.isEmpty {
//                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as! NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
//
//                for recent in sorted {
//                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil{
//                        self.recentChats.append(recent)
//                    }
//                }
//                self.tableView.reloadData()
//            }
//        }
//    }
    
    func loadRecentChats() {
        
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            self.recentChats = []
            
            if !snapshot.isEmpty {
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                
                for recent in sorted {
                    
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                        
                        self.recentChats.append(recent)
                    }
                    
                    reference(.Recent).whereField(kCHATROOMID, isEqualTo: recent[kCHATROOMID] as! String).getDocuments(completion: { (snapshot, error) in
                        
                    })
                }
                
                self.tableView.reloadData()
            }
        })
    }
    
    
    func setTableViewController(){
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 45))
        let buttonView = UIView(frame: CGRect(x: 0, y: 5, width: self.tableView.frame.width, height: 35))
        let groupButton = UIButton(frame: CGRect(x: tableView.frame.width - 150, y: 5, width: 100, height: 20))
        groupButton.addTarget(self, action: #selector(self.groupButtonPressed), for: .touchUpInside)
        groupButton.setTitle("New Group", for: .normal)
        let buttonColour = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        groupButton.setTitleColor(buttonColour, for: .normal)
        
        let lineView = UIView(frame: CGRect(x: 0, y: headerView.frame.height - 1, width: tableView.frame.width, height: 1))
        lineView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        buttonView.addSubview(groupButton)
        headerView.addSubview(buttonView)
        headerView.addSubview(lineView)
        tableView.tableHeaderView = headerView
    }
    
    @objc func groupButtonPressed(){
        selectUserForChat(isGroup: true)
    }
    
    // MARK: Recent Chat cell Delegate
    func didTappedAvatarImage(indexPath: IndexPath) {
        
        var recentChat : NSDictionary
        
        if searchController.isActive && searchController.searchBar.text != "" {
            recentChat = filteredChat[indexPath.row]
        }else{
            recentChat = recentChats[indexPath.row]
        }
        
        if recentChat[kTYPE] as! String == kPRIVATE {
            reference(.User).document(recentChat[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
                guard let snapshot = snapshot else {return}
                
                if snapshot.exists {
                    let userDictionary = snapshot.data() as! NSDictionary
                    let tempUser = FUser(_dictionary: userDictionary)
                    self.showUserProfile(user: tempUser)
                    
                }
            }
        }
    }
    
    func showUserProfile(user: FUser){
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        
        profileVC.user = user
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    //MARK: Search Controller Function
    
    func filterContentForSearch(searchText: String, scope: String = "All"){
        filteredChat = recentChats.filter({ (recentChat) -> Bool in
            return (recentChat[kWITHUSERUSERNAME] as! String).lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearch(searchText: searchController.searchBar.text!)
    }
    
    // MARK: Helper Function
    func updatePushMembers(recent: NSDictionary, mute: Bool){
        
        var memebersToPush = recent[kMEMBERSTOPUSH] as! [String]
        if mute {
            let index = memebersToPush.index(of: FUser.currentId())!
            memebersToPush.remove(at: index)
        }else {
            memebersToPush.append(FUser.currentId())
        }
        // Save The Changes to Firestore
        updateExistingRicentWithNewValues(chatRoomId: recent[kCHATROOMID] as! String, members: recent[kMEMBERS] as! [String], withValues: [kMEMBERSTOPUSH : memebersToPush])
    }
    
    func selectUserForChat(isGroup: Bool){
        let contactsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "contactsView") as! ContactsTableViewController
        
        contactsVC.isGroup = isGroup
        self.navigationController?.pushViewController(contactsVC, animated: true)
    }
    
}
