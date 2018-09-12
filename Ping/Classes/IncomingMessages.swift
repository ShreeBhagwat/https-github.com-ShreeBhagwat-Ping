//
//  IncomingMessages.swift
//  Ping
//
//  Created by Gauri Bhagwat on 07/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessages{
    var collectionView: JSQMessagesCollectionView
    
    init(collectionView_: JSQMessagesCollectionView) {
        collectionView = collectionView_
        
    }
    // MARK: Create Message
    func createMessage(messageDictionary: NSDictionary, chatroomId: String) -> JSQMessage? {
        var message : JSQMessage?
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kTEXT:
            //Create Text Message
            print("Text Message")
            message = createTextMessage(messageDictionary: messageDictionary, charoomId: chatroomId)
        case kPICTURE:
        //Create Picture Message
            message = createPictureMessage(messageDictionary: messageDictionary)
        case kVIDEO:
        //Create Video Message
            message = createVideoMessage(messageDictionary: messageDictionary)
        case kAUDIO:
        //Create Audio Message
               message = createAudioMessage(messageDictionary: messageDictionary)
        case kLOCATION:
        //Create Location Message
               message = createLocationMessage(messageDictionary: messageDictionary)

        default:
            print("Unknown Message Type")
        }
        
        if message != nil {
            return message
        }
        
        return nil
    }
    // MARK: Create Message Types
    
    func createTextMessage(messageDictionary: NSDictionary, charoomId: String) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as! String
        let userId = messageDictionary[kSENDERID] as! String
        
        var date: Date!
        
        if let created =  messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        }
        else {
            date = Date()
        }
        let text = messageDictionary[kMESSAGE] as! String
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: text)
    }
    
    // Picture Function
    
    func createPictureMessage(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as! String
        let userId = messageDictionary[kSENDERID] as! String
        
        var date: Date!
        
        if let created =  messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        }
        else {
            date = Date()
        }
        let mediaItem = PhotoMediaItem(image: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutGoingStatusForUser(senderId: userId)
        // Download Image
        downloadImage(imageURl: messageDictionary[kPICTURE] as! String) { (image) in
            if image != nil {
                mediaItem?.image = image!
                self.collectionView.reloadData()
            }
        }
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    // Video Function
    
    
    func createVideoMessage(messageDictionary: NSDictionary) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as! String
        let userId = messageDictionary[kSENDERID] as! String
        
        var date: Date!
        
        if let created =  messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        }
        else {
            date = Date()
        }
        let videoUrl = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        
        let mediaItem = VideoMessage(withFileUrl: videoUrl, maskOutgoing: returnOutGoingStatusForUser(senderId: userId))
        // Download Video
        downloadVideo(videoURL: messageDictionary[kVIDEO] as! String) { (isReadyToPlay, fileName) in
            let URL = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
            mediaItem.status = kSUCCESS
            mediaItem.fileURL = URL
         
            imageFromData(pictureData: messageDictionary[kTHUMBNAIL] as! String, withBlock: { (image) in
                if image != nil{
                mediaItem.image = image!
                self.collectionView.reloadData()
            }
            })
            self.collectionView.reloadData()
        }
     
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    // Create Audio Message
    
    func createAudioMessage(messageDictionary: NSDictionary) -> JSQMessage {
        // Common Part for all message
        let name = messageDictionary[kSENDERNAME] as! String
        let userId = messageDictionary[kSENDERID] as! String
        
        var date: Date!
        
        if let created =  messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        }
        else {
            date = Date()
        }
        // Change from below
        
        let audioItem = JSQAudioMediaItem(data: nil)
        audioItem.appliesMediaViewMaskAsOutgoing = returnOutGoingStatusForUser(senderId: userId)
        
        let audioMessage = JSQMessage(senderId: userId, displayName: name, media: audioItem)
        
        
        // Download Audio
        downloadAudio(audioURl: messageDictionary[kAUDIO] as! String) { (fileName) in
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
            let audioData = try? Data(contentsOf: url as URL)
            audioItem.audioData = audioData
            self.collectionView.reloadData()
        }
        
        return audioMessage!
    }
    
    // Location Message
    
    func createLocationMessage(messageDictionary: NSDictionary) -> JSQMessage {
        // Same Old Function blabla
        let name = messageDictionary[kSENDERNAME] as! String
        let userId = messageDictionary[kSENDERID] as! String
        
        var date: Date!
        
        if let created =  messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        }
        else {
            date = Date()
        }
        // Yeah lets start new here
        let text = messageDictionary[kMESSAGE] as! String
        let latitude = messageDictionary[kLATITUDE] as? Double
        let longitude = messageDictionary[kLONGITUDE] as? Double
        
        let mediaItem = JSQLocationMediaItem(location: nil)
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutGoingStatusForUser(senderId: userId)
        
        let location = CLLocation(latitude: latitude!, longitude: longitude!)
        
        mediaItem?.setLocation(location, withCompletionHandler: {
            self.collectionView.reloadData()
        })
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    
    // Helper Function
    func returnOutGoingStatusForUser(senderId: String) -> Bool {
    return senderId == FUser.currentId()
    }
}


