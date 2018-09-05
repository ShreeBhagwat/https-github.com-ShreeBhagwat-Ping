//
//  Recent.swift
//  Ping
//
//  Created by Gauri Bhagwat on 04/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation

func startPrivateChat(user1: FUser, user2: FUser) -> String {
    let userId1 = user1.objectId
    let userId2 = user2.objectId
    
    var chatRoomId = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0 {
        chatRoomId = userId1 + userId2
    }else {
        chatRoomId = userId2 + userId1
    }
    
    let memeber = [userId1, userId2]
    
    createRecentChat(members: memeber, chatRoomId: chatRoomId, withUserUserName: "", type: kPRIVATE, users: [user1, user2], avatarOfGroups: nil)
    
    // Create Recent Chat
    
    return chatRoomId
}

func createRecentChat(members: [String], chatRoomId: String, withUserUserName: String, type: String, users: [FUser?], avatarOfGroups: String?){
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        var tempMembers = members
        
        guard let snapshot = snapshot else {return}
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                
                if let currentUserId = currentRecent[kUSERID] {
                    if tempMembers.contains(currentUserId as! String) {
                        tempMembers.remove(at: tempMembers.index(of: currentUserId as! String)!)
                    }
                }
            }
        }
        for userId in tempMembers {
            // Create Recent Items
            createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUserName: withUserUserName, type: type, users: users as! [FUser], avatarOfGroups: avatarOfGroups)
        }
    }
}


func createRecentItem(userId: String, chatRoomId: String, members:[String], withUserUserName: String, type: String, users: [FUser]?, avatarOfGroups: String?){
    
    let localReference = reference(.Recent).document()
    let recentId = localReference.documentID
    let date = dateFormatter().string(from: Date())
    var recent: [String: Any]!
    
    if type == kPRIVATE {
        //Private
        var withUsers: FUser?
        
        if users != nil && users!.count > 0 {
            if userId == FUser.currentId(){
                // for current user
                withUsers = users!.last!
            }else {
                withUsers = users!.first!
            }
        }
        
        recent = [kRECENTID: recentId,
                  kUSERID: userId,
                  kCHATROOMID: chatRoomId,
                  kMEMBERS: members,
                  kMEMBERSTOPUSH: members,
                  kWITHUSERUSERNAME: withUsers!.fullname,
                  kWITHUSERUSERID: withUsers!.objectId,
                  kLASTMESSAGE: "",
                  kCOUNTER: 0,
                  kDATE: date,
                  kTYPE: type,
                  kAVATAR: withUsers!.avatar] as [String: Any]
    }else{
        //Group
        if avatarOfGroups != nil {
            recent = [kRECENTID: recentId,
                      kUSERID: userId,
                      kCHATROOMID: chatRoomId,
                      kMEMBERS: members,
                      kMEMBERSTOPUSH: members,
                      kWITHUSERFULLNAME: withUserUserName,
                      kLASTMESSAGE: "",
                      kCOUNTER: 0,
                      kDATE: date,
                      kTYPE: type,
                      kAVATAR: avatarOfGroups!] as [String: Any]
        }
    }
    // Save Recent Chat.
    localReference.setData(recent)
}
