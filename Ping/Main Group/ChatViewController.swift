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

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  

    @IBOutlet weak var tableView: UITableView!
    var recentChat: [NSDictionary] = []
    var filteredChat: [NSDictionary] = []
    var recentListner: ListenerRegistration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        loadRecentChats()
    }
    
    //Mark:- IBAction
    
    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userTableView") as! UsersTableViewController
        self.navigationController?.pushViewController(userVC, animated: true)
    }
    
    // MARK: Tableview delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return recentChat.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath) as! RecentChatTableViewCell
        let recent = recentChat[indexPath.row]
        cell.generateCell(recentChat: recent, indexPath: indexPath)

        return cell
    }
    
    // MARK: Load Recent Chats.
    
    func loadRecentChats(){
        recentListner = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {return}
            self.recentChat = []
            if !snapshot.isEmpty {
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as! NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                
                for recent in sorted {
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil{
                        self.recentChat.append(recent)
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
}
