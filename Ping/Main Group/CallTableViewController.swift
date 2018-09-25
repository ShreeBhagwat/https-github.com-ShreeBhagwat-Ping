//
//  CallTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 21/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseFirestore


class CallTableViewController: UITableViewController,UISearchResultsUpdating {
    
    //MARK: Variables
    var allCalls: [CallClass] = []
    var filteredCalls: [CallClass] = []

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let searchController = UISearchController(searchResultsController: nil)
    var callListner: ListenerRegistration!
     var user : FUser?
    //MARK: ViewFunction

    override func viewWillAppear(_ animated: Bool) {
        // Load All Codes
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        loadCalls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         AppUtility.lockOrientation(.all)
        callListner.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBadge(controller: self.tabBarController!)
        tableView.tableFooterView = UIView()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        // Search Controller
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
       
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCalls.count
        }
        return allCalls.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "callCell", for: indexPath) as! CallTableViewCell
        
        var call: CallClass!
        if searchController.isActive && searchController.searchBar.text != "" {
            call = filteredCalls[indexPath.row]
        } else {
            call = allCalls[indexPath.row]

        }
        cell.generateCellWith(call: call)
        return cell
    }
    
    // MARK: TableView Delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var tempCall: CallClass

            if searchController.isActive && searchController.searchBar.text != "" {
                tempCall = filteredCalls[indexPath.row]
                filteredCalls.remove(at: indexPath.row)
            } else {
                tempCall = allCalls[indexPath.row]
                allCalls.remove(at: indexPath.row)
            }
            tempCall.deleteCall()
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var userToCall :String = ""
        var name:String = ""
        print(FUser.currentId())
        if allCalls[indexPath.row].callerId == FUser.currentId() {
            userToCall = allCalls[indexPath.row].withUserId
            name = allCalls[indexPath.row].withUserFullName
            print("inside the if \(userToCall)")
            print("inside the if \(name)")
        } else {
            userToCall = allCalls[indexPath.row].callerId
            print("inside the else \(userToCall)")
            name = allCalls[indexPath.row].callerFullName
            print("inside the else \(name)")
        }
       
        callUser(userToCall: userToCall)
        let currentUser = FUser.currentUser()!
        let call = CallClass(_calledId: currentUser.objectId, _withUserId: userToCall, _callerFullName: currentUser.fullname, _withUserFullName: name)

        call.saveCallInBackground()
    }
    
   
    
    //MARK: Load Calls
    func loadCalls(){
        callListner = reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).order(by: kDATE, descending: true).limit(to: 20).addSnapshotListener({ (snapshot, error) in
           
            self.allCalls = []
            guard let snapshot = snapshot else {return}
            
            if !snapshot.isEmpty {
                let sortedDictionary = dictionaryFromSnapshots(snapshots: snapshot.documents)
                
                for callDictionary in sortedDictionary {
                    let call = CallClass(_dicitionary: callDictionary)
                    self.allCalls.append(call)
                }
            }
            self.tableView.reloadData()
        })
    }

    // MARK: SearchView Delegate
    func filteredContentForText(searchText: String, scope: String = "All"){
        filteredCalls = allCalls.filter({ (call) -> Bool in
            var callerName : String!
            
            if call.callerId == FUser.currentId() {
                callerName = call.withUserFullName
            } else {
                callerName = call.callerFullName
            }
            return (callerName).lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForText(searchText: searchController.searchBar.text!)
    }
    
    // Call User
    func callClient() -> SINCallClient {
        
        return appDelegate._client.call()
    }
    
    func callUser (userToCall: String) {
        
        let callToBeMade = callClient().callUser(withId: userToCall)
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
        callVC._call = callToBeMade
        self.present(callVC, animated: true, completion: nil)
        
    }

}
