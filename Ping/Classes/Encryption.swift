//
//  Encryption.swift
//  Ping
//
//  Created by Gauri Bhagwat on 20/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation
import RNCryptor

class Encryption {

        class func encryptText(chatRoomId: String, message: String) -> String {
            let data = message.data(using: String.Encoding.utf8)
            let encryptedData = RNCryptor.encrypt(data: data!, withPassword: chatRoomId)
            return encryptedData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
        }
        
        class func decryptText(chatRoomId: String, encryptedMessage: String) -> String {
            let decryptor = RNCryptor.Decryptor(password: chatRoomId)
            let encryptedData = NSData(base64Encoded: encryptedMessage, options: NSData.Base64DecodingOptions(rawValue: 0))
            var message: NSString = ""
            if encryptedData != nil {
                do {
                    let decryptedData = try decryptor.decrypt(data: encryptedData! as Data)
                    message = NSString(data: decryptedData, encoding: String.Encoding.utf8.rawValue)!
                } catch {
                    print("error in decryption \(error.localizedDescription) ")
                }
            }
            return message as String
        }
    
    class func encryptImages(chatRoomId: String, image: UIImage) -> Data {
        let imageData: Data = image.pngData()!
        let encryptedImage = RNCryptor.encrypt(data: imageData, withPassword: chatRoomId)
        return encryptedImage
    }
    
    class func decryptImages(chatRoomId: String, encryptedImage: Data) -> Data{
        let decryptor = RNCryptor.Decryptor(password: chatRoomId)
        var dataToReturn : Data!
        do {
            let decryptionResult = try decryptor.decrypt(data: encryptedImage)
            dataToReturn = decryptionResult
        } catch {
            print("error in decryption \(error.localizedDescription)")
        }
        return dataToReturn
        
    }
    
    class func encryptAudio(chatRoomId: String, inputData: NSData) -> Data {
        //let imageData: Data = image.pngData()!
        let encryptedData = RNCryptor.encrypt(data: inputData as Data, withPassword: chatRoomId)
        return encryptedData
    }
    
    class func decryptAudio(chatRoomId: String, encryptedData: NSData) -> NSData{
        let decryptor = RNCryptor.Decryptor(password: chatRoomId)
        var dataToReturn : NSData!
        do {
            let decryptionResult = try decryptor.decrypt(data: encryptedData as Data)
            dataToReturn = decryptionResult as NSData
        } catch {
            print("error in decryption \(error.localizedDescription)")
        }
        return dataToReturn
        
    }
    
    class func encryptVideos(chatRoomId: String, video: Data) -> Data {
        //let videoData: Data = image.pngData()!
        let encryptedVideo = RNCryptor.encrypt(data: video, withPassword: chatRoomId)
        return encryptedVideo
    }
    
    class func decryptVideos(chatRoomId: String, encryptedVideo: Data) -> Data{
        let decryptor = RNCryptor.Decryptor(password: chatRoomId)
        var dataToReturn : Data!
        do {
            let decryptionResult = try decryptor.decrypt(data: encryptedVideo)
            dataToReturn = decryptionResult
        } catch {
            print("error in decryption \(error.localizedDescription)")
        }
        return dataToReturn
        
    }
    
}

