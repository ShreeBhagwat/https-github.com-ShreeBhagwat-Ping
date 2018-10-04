//
//  SettingsTableTableViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 31/08/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingsTableTableViewController: UITableViewController {
    
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var deleteAccountButtonOutlet: UIButton!
    @IBOutlet weak var avatarStatusSwitch: UISwitch!
    
    @IBOutlet weak var userBioLabelOutlet: UILabel!
    @IBOutlet weak var logoutButtonOutlet: UIButton!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    
    
    var avatarSwitchStatus = false
    let userDefaults = UserDefaults.standard
    var firstLoad: Bool?
    override func viewDidAppear(_ animated: Bool) {
        if FUser.currentUser() != nil {
            setupUI()
            loadUserDefaults()
            
            if Reachability.isConnectedToNetwork(){
                
            }else{
                ProgressHUD.showError("No Connection")
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        } else {
            // Fallback on earlier versions
        }
        navigationController?.navigationBar.barTintColor = UIColor.flatBlue()
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        tableView.tableFooterView = UIView()
        

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 5
        }else {
            return 2
        }
    }
    // MARK: TableView Delegate
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
    
    // MARK: IBActions
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
      
    }
    
    
    
    @IBAction func tellAFriendButtonPressed(_ sender: Any) {
        let text = "Hey ping me\(kAPPURL)"
        let objectsToShare: [Any] = [text]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.setValue("Lets Chat On Ping", forKey: "subject")
        self.present(activityViewController, animated: true, completion: nil)
        
    }

    @IBAction func cleanCacheButtonPressed(_ sender: Any) {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: getDocumentsURL().path)
            for file in files {
                try FileManager.default.removeItem(atPath: "\(getDocumentsURL().path)/\(file)")
            }
            ProgressHUD.showSuccess("Clean Cache Media Files Successful")
        }catch{
            ProgressHUD.showError("Could Not Clean Cache Media Files")
        }
    }
    
    @IBAction func showAvatarSwitchValueChanged(_ sender: UISwitch) {
//        if sender.isOn {
//            avatarSwitchStatus = true
//        } else {
//            avatarSwitchStatus = false
//        }
        
        avatarSwitchStatus = sender.isOn
        // Save To User Defaults
        saveUserDefaults()
        
        
    }

    @IBAction func logOutButtonPressed(_ sender: Any) {
        let optionMenu = UIAlertController(title: "Log Out", message: "Are you sure you want Log Out", preferredStyle: .actionSheet)
        let logoutAction = UIAlertAction(title: "Log Out", style: .default) { (alert) in
            FUser.logOutCurrentUser { (success) in
                if success {
                    //Show Login View
                    self.showLoginView()
                    
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (aler) in
        }
        optionMenu.addAction(logoutAction)
        optionMenu.addAction(cancelAction)
        
        // For Ipad Alert Controller
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverpresentationController = optionMenu.popoverPresentationController {
                currentPopoverpresentationController.sourceView = logoutButtonOutlet
                currentPopoverpresentationController.sourceRect = logoutButtonOutlet.bounds
                
                currentPopoverpresentationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else {
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func deleteAccountButtonPressed(_ sender: Any) {
        let optionMenu = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete the account ", preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (alert) in
            // Delete the user
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
        }
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        
        // For Ipad Alert Controller
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverpresentationController = optionMenu.popoverPresentationController {
                currentPopoverpresentationController.sourceView = deleteAccountButtonOutlet
                currentPopoverpresentationController.sourceRect = deleteAccountButtonOutlet.bounds
                
                currentPopoverpresentationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else {
            self.present(optionMenu, animated: true, completion: nil)
        }
        
    }
    
    func showLoginView(){
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcome")
        self.present(mainView, animated: true, completion: nil)
    }
    
    // MARK: Setup UI
    func setupUI(){
        let currentUser = FUser.currentUser()!
        userBioLabelOutlet.text = currentUser.bio
        fullNameLabel.text = currentUser.fullname
        if currentUser.avatar != "" {
            imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                    
                }
            }
        }
        // Set up Version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = version
        }
    }
    // MARK: Delete User
    func deleteUser(){
        // Delete Locally
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        
        // delete From Firebase
        
        reference(.User).document(FUser.currentId()).delete()
        
        FUser.deleteUser { (error) in
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError("Could not delete User")
                }
                return
            }
            
            self.showLoginView()
        }
    }
    
    // MARK: UserDefaults
    func saveUserDefaults(){
        userDefaults.setValue(avatarSwitchStatus, forKey: kSHOWAVATAR)
        userDefaults.synchronize()
    }
    
    func loadUserDefaults(){
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
            if !firstLoad! {
                userDefaults.set(true, forKey: kFIRSTRUN)
                userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
                userDefaults.synchronize()
        }
        avatarSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
        avatarStatusSwitch.isOn = avatarSwitchStatus
    }
}
