//
//  Group.swift
//  Ping
//
//  Created by Gauri Bhagwat on 19/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation
import FirebaseFirestore
import ProgressHUD
class Group {
    let groupDistionary : NSMutableDictionary
    
    init(groupId: String, subject: String, ownerId: String, adminsId: [String]?, members: [String], avatar: String) {
        groupDistionary = NSMutableDictionary(objects: [groupId, subject, ownerId, adminsId, members, members, avatar ], forKeys: [kGROUPID as NSCopying, kNAME as NSCopying, kOWNERID as NSCopying, kADMINID as NSCopying, kMEMBERS as NSCopying, kMEMBERSTOPUSH as NSCopying, kAVATAR as NSCopying])
    }
    
    func saveGroup(){
        let date = dateFormatter().string(from: Date())
        groupDistionary[kDATE] = date
        reference(.Group).document(groupDistionary[kGROUPID] as! String).setData(groupDistionary as! [String : Any])
    }
    
    class func updateGroup(groupId: String, withValues: [String: Any]){
        reference(.Group).document(groupId).updateData(withValues)
    }
    
  

}
