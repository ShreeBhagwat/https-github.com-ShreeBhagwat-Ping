//
//  OutgoingMessages.swift
//  Ping
//
//  Created by Gauri Bhagwat on 07/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation

class OutgoingMessages {
    let messageDictionary: NSMutableDictionary
    
    //MARK: Init
    // TextMessage Init
    
    init(message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as! NSCopying, kSENDERID as! NSCopying, kSENDERNAME as! NSCopying, kDATE as! NSCopying, kSTATUS as! NSCopying, kTYPE as! NSCopying])
    }
    
    // MARK: Send Message
    func sendMessage(chatroomId: String, messageDictionary: NSMutableDictionary, membersId: [String], membersToPush: [String]){
        let messageId = UUID().uuidString
        messageDictionary[kMESSAGEID] = messageId
        
        for memberId in membersId {
            reference(.Message).document(memberId).collection(chatroomId).document(messageId).setData(messageDictionary as! [String: Any])
        }
        
        // Update RecentChats to show last message
        
        // PushNotification to Reciever
    }
}


