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
    
    createRecent(members: memeber, chatRoomId: chatRoomId, withUserUserName: "", type: kPRIVATE, users: [user1, user2], avatarOfGroups: nil)
    
    // Create Recent Chat
    
    return chatRoomId
}

func createRecent(members: [String], chatRoomId: String, withUserUserName: String, type: String, users: [FUser]?, avatarOfGroups: String?){
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
            createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUserName: withUserUserName, type: type, users: users as [FUser]?, avatarOfGroups: avatarOfGroups)
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
                      kWITHUSERUSERNAME: withUserUserName,
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

// MARK: Restart Chat
func restartRecentChat(recent: NSDictionary){
    if recent[kTYPE] as! String == kPRIVATE {
        createRecent(members: [kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: FUser.currentUser()!.firstname, type: kPRIVATE, users:[FUser.currentUser()!], avatarOfGroups: nil)
    }
    if recent[kTYPE] as! String == kGROUP {
      
        createRecent(members: [kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: recent[kWITHUSERUSERNAME] as! String, type: kGROUP, users: nil, avatarOfGroups: recent[kAVATAR] as! String)
    }
    
}
// MARK: Update Recent
func updateRecents(chatroomId: String, lastMessage: String){
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatroomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else {return}
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                updateRecentItem(recent: currentRecent, lastMessage: lastMessage)
            }
        }
    }
}

func updateRecentItem(recent: NSDictionary, lastMessage: String){
    let date = DateFormatter().string(from: Date())
    var counter = recent[kCOUNTER] as! Int
    if recent[kUSERID] as? String != FUser.currentId() {
        counter += 1
    }
    let values = [kLASTMESSAGE : lastMessage, kCOUNTER : counter, kDATE : date] as! [String : Any]
    reference(.Recent).document(recent[kRECENTID] as! String).updateData(values)
}

// MARK: Delete Recent.
func deleteRecentChat(recentChatDictionary: NSDictionary){
    if let recentId = recentChatDictionary[kRECENTID] {
        reference(.Recent).document(recentId as! String).delete()
    }
    
}

// MARK: Clear Counter
func clearRecentCounter(chatroomId: String){
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatroomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else {return}
        
        if !snapshot.isEmpty {
            
            for recent in snapshot.documents {
                let currentRecent = recent.data() as NSDictionary
                if currentRecent[kUSERID] as? String == FUser.currentId() {
                    clearRecentCounterItem(recent: currentRecent)
                }
            }
        }
    }
}

func clearRecentCounterItem(recent: NSDictionary){
    reference(.Recent).document(recent[kRECENTID] as! String).updateData([kCOUNTER: 0])
}

// Group

func startGroupChat(group : Group){
    let charoomId = group.groupDistionary[kGROUPID] as! String
    let members = group.groupDistionary[kMEMBERS] as! [String]

    
    createRecent(members: members, chatRoomId: charoomId, withUserUserName: group.groupDistionary[kNAME] as! String, type: kGROUP, users: nil, avatarOfGroups: group.groupDistionary[kAVATAR] as? String)
    
}


func createRecentForNewMember(groupId: String, groupName: String, membersToPush: [String], avatar: String){
    createRecent(members: membersToPush, chatRoomId: groupId, withUserUserName: groupName, type: kGROUP, users: nil, avatarOfGroups: avatar)
}




func updateExistingRecentWithNewValues(chatroomId: String, members: [String], withValues: [String : Any]){
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatroomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else{return}
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let recent = recent.data() as! NSDictionary
                updateRecent(recentId: recent[kRECENTID] as! String, withValues: withValues)
            }
        }
    }

}

func updateRecent(recentId: String, withValues: [String:Any]){
    reference(.Recent).document(recentId).updateData(withValues)
}

// MARK: Block User

func blockUser(userToBlock: FUser){
    let userId1 = FUser.currentId()
    let userId2 = userToBlock.objectId
    
    var chatRoomId = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0 {
        chatRoomId = userId1 + userId2
    }else {
        chatRoomId = userId2 + userId1
    }
    getRecentsFor(chatroomId: chatRoomId)
}

func getRecentsFor(chatroomId: String){
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatroomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else{return}
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                let recent = recent.data() as! NSDictionary
                deleteRecentChat(recentChatDictionary: recent)
            }
        }
    }
    
}
