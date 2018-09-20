//
//  IncomingMessages.swift
//  Ping
//
//  Created by Gauri Bhagwat on 07/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessages {
    
    
    var collectionView: JSQMessagesCollectionView
    
    init(collectionView_: JSQMessagesCollectionView) {
        collectionView = collectionView_
    }
    
    //MARK: Create Message
    
    func createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage? {
        
        var message: JSQMessage?
        
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kTEXT:
            message = createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        case kPICTURE:
            message = createPictureMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        case kVIDEO:
            message = createVideoMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        case kAUDIO:
            message = createAudioMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        case kLOCATION:
            message = createLocationMessage(messageDictionary: messageDictionary)
        default:
            print("unknown message type")
        }
        if message != nil {
            return message
        }
        
        return nil
    }
    
    func  createTextMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        var date : Date!
        if let createdDate = messageDictionary[kDATE] {
            if (createdDate as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: createdDate as! String)
            }
        }else {
            date = Date()
        }
        
        let decryptedText = Encryption.decryptText(chatRoomId: chatRoomId, encryptedMessage: messageDictionary[kMESSAGE] as! String)
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: decryptedText)
    }
    
    func createPictureMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date : Date!
        if let createdDate = messageDictionary[kDATE] {
            if (createdDate as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: createdDate as! String)
            }
        }else {
            date = Date()
        }
        
        let mediaItem = PhotoMediaItem(image: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!)
        
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String, chatRoomId: chatRoomId) { (image) in
            if image != nil {
                mediaItem?.image = image!
                self.collectionView.reloadData()
                
            }
        }
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    func createVideoMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date : Date!
        if let createdDate = messageDictionary[kDATE] {
            if (createdDate as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: createdDate as! String)
            }
        }else {
            date = Date()
        }
        
        let videoURL = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        let mediaItem = VideoMessage(withFileUrl: videoURL, maskOutgoing: returnOutgoingStatusForUser(senderId: userId!))
        
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String, chatRoomId: chatRoomId) { (isReadyToPlay, fileName) in
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
            mediaItem.status = kSUCCESS
            mediaItem.fileURL = url
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String, withBlock: { (image) in
                if image != nil {
                    mediaItem.image = image!
                    self.collectionView.reloadData()
                }
            })
            
            self.collectionView.reloadData()
        }
        
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
        
    }
    
    
    func createAudioMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date : Date!
        if let createdDate = messageDictionary[kDATE] {
            if (createdDate as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: createdDate as! String)
            }
        }else {
            date = Date()
        }
        
        let audioItem = JSQAudioMediaItem(data: nil)
        audioItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!)
        let audioMessage = JSQMessage(senderId: userId!, displayName: name!, media: audioItem)
        
        downloadAudio(audioUrl: (messageDictionary[kAUDIO] as! String), chatRoomId: chatRoomId) { (fileName) in
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
            let audioData = try? Data(contentsOf: url as URL)
            audioItem.audioData = audioData
            self.collectionView.reloadData()
        }
        
        return audioMessage!
        
    }
    
    func  createLocationMessage(messageDictionary: NSDictionary) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        var date : Date!
        if let createdDate = messageDictionary[kDATE] {
            if (createdDate as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: createdDate as! String)
            }
        }else {
            date = Date()
        }
        
        let latitude = messageDictionary[kLATITUDE] as? Double
        let longitude = messageDictionary[kLONGITUDE] as? Double
        
        let mediaItem = JSQLocationMediaItem(location: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!)
        let location = CLLocation(latitude: latitude!, longitude: longitude!)
        mediaItem?.setLocation(location, withCompletionHandler: {
            self.collectionView.reloadData()
        })
        
        return JSQMessage(senderId: userId!, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    //Helpers
    
    func returnOutgoingStatusForUser(senderId: String) -> Bool {
        
        return senderId == FUser.currentId()
    }
}


