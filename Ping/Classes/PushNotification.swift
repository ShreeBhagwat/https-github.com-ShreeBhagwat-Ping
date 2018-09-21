//
//  PushNotification.swift
//  Ping
//
//  Created by Gauri Bhagwat on 21/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation
import OneSignal

func sendPushNotification(memberToPush: [String], message: String) {
    let updatedMembers = removeCurrentUserFromMembersArray(members: memberToPush)
    getMembersToPush(members: updatedMembers) { (userPushIds) in
        let currentUser = FUser.currentUser()!
        OneSignal.postNotification(["contents" : ["en" : "\(currentUser.firstname) \n \(message)"],
                                    "ios_badgeType" : "Increase",
                                    "ios_badgeCount" : "1",
                                    "include_player_ids" : userPushIds])
    }
}
func removeCurrentUserFromMembersArray(members: [String]) -> [String] {
    var updateMembers : [String] = []
    for memberID in members {
        if memberID != FUser.currentId() {
            updateMembers.append(memberID)
        }
    }
    return updateMembers
}

func getMembersToPush(members: [String], completion: @escaping (_ UsersArray: [String]) -> Void) {
    var pushIds: [String] = []
    var count = 0
    
    for memberId in members {
        reference(.User).document(memberId).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else {completion(pushIds); return}
            
            if snapshot.exists {
                let userDictionary = snapshot.data() as! NSDictionary
                
                let fUser = FUser.init(_dictionary: userDictionary)
                pushIds.append(fUser.pushId!)
                count += 1
                
                if members.count == count {
                    completion(pushIds)
                }
                
            } else {
                completion(pushIds)
                
            }
        }
    }
}
