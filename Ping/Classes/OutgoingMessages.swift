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
        
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // Picture Message Init
    init(message: String, pictureLink: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, pictureLink,  senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kPICTURE as NSCopying,  kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // Video Message Init
    init(message: String, video: String, thumbnail: NSData, senderId: String, senderName: String, date: Date, status: String, type: String) {
        // Creating ThumbNail for Video
        let picThumbnail = thumbnail.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
       
         messageDictionary = NSMutableDictionary(objects: [message, video, picThumbnail,   senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kVIDEO as NSCopying, kTHUMBNAIL as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // Audio Message Init

    init(message: String, audioLink: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, audioLink,  senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kAUDIO as NSCopying,  kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    // Location Message
    
    init(message: String, Latitude: NSNumber, Longitude: NSNumber, senderId: String, senderName: String, date: Date, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, Latitude, Longitude, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kLATITUDE as NSCopying, kLONGITUDE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
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


