//
//  Downloader.swift
//  Ping
//
//  Created by Gauri Bhagwat on 09/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD
import AVFoundation

let storage = Storage.storage()

// MARK: Image Upload

func uploadImage(image: UIImage, chatRoomId: String, view: UIView, completion: @escaping (_ imageLink: String?) -> Void) {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    let dateString = dateFormatter().string(from: Date())
    let photoFileName = "PictureMessage/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".jpg"
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
    
    let encryptedImageData =  Encryption.encryptImages(chatRoomId: chatRoomId, image: image)
    
    var task : StorageUploadTask!
    
    task = storageRef.putData(encryptedImageData, metadata: nil, completion: { (metaData, error) in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        if error != nil {
            print("Image upload Error \(error?.localizedDescription)")
            return
        }
        
        storageRef.downloadURL(completion: { (url, error) in
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
            
        })
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
    
    
    
    
    
}

//MARK: DownLoad Image

func downloadImage(imageUrl: String, chatRoomId: String, completion: @escaping(_ image: UIImage?) -> Void) {
    
    let imageURL = NSURL(string: imageUrl)
    
    let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    
    if fileExistAtPath(path: imageFileName) {
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
            completion(contentsOfFile)
        } else {
            print("could not generate image")
            completion(nil)
        }
    } else {
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        
        downloadQueue.async {
            
            let fetchedData = try? Data(contentsOf: imageURL! as URL)
            if fetchedData != nil {
                let decryptedData = Encryption.decryptImages(chatRoomId: chatRoomId, encryptedImage: fetchedData!)
                
                var docURL = getDocumentsURL()
                docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                try? decryptedData.write(to: docURL, options: Data.WritingOptions.atomic)
                let imageToReturn = UIImage(data: decryptedData)!
                DispatchQueue.main.async {
                    completion(imageToReturn)
                }
            }else {
                DispatchQueue.main.async {
                    print("no image in database")
                    completion(nil)
                }
                
            }
        }
    }
    
}




//Video Upload & Download

func uploadVideo(video: NSData, chatRoomId: String, view: UIView, compleltion: @escaping(_ videoLink: String?) -> Void){
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    let dateString = dateFormatter().string(from: Date())
    let videoFileName = "VideoMessage/" + FUser.currentId() + "/" + dateString + ".mov"
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
    var task : StorageUploadTask!
    let encryptedVideo = Encryption.encryptVideos(chatRoomId: chatRoomId, video: video as Data)
    task = storageRef.putData(encryptedVideo , metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        if error != nil {
            print("upload video error \(error!.localizedDescription)")
            return
        }
        storageRef.downloadURL(completion: { (url, error) in
            guard let downloadUrl = url else {
                compleltion(nil)
                return
                
            }
            compleltion(downloadUrl.absoluteString)
        })
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
    
}




func downloadVideo(videoUrl: String,chatRoomId: String , completion: @escaping(_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
    
    let videoURL = NSURL(string: videoUrl)
    
    let videoFileName = (videoUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    
    if fileExistAtPath(path: videoFileName) {
        //Video Exist
        completion(true, videoFileName)
        
    } else {
        let downloadQueue = DispatchQueue(label: "videoDownloadQueue")
        
        downloadQueue.async {
            let fetchedData = try? Data(contentsOf: videoURL! as URL)
            if fetchedData != nil {
                let decryptedData = Encryption.decryptVideos(chatRoomId: chatRoomId, encryptedVideo: fetchedData!)
                
                var docURL = getDocumentsURL()
                docURL = docURL.appendingPathComponent(videoFileName, isDirectory: false)
                try? decryptedData.write(to: docURL, options: Data.WritingOptions.atomic)
                
                DispatchQueue.main.async {
                    completion(true, videoFileName)
                }
            } else {
                DispatchQueue.main.async {
                    print("no vidoe in database")
                    
                }
                
            }
        }
    }
    
}

// Audio Uploade & Download

func uploadAudio(audioPath: String, chatRoomId: String, view: UIView, compleltion: @escaping(_ audioLink: String?) -> Void)  {
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    let dateString = dateFormatter().string(from: Date())
    let audioFileName = "AudioMessage/" + FUser.currentId() + "/" + dateString + ".m4a"
    let audio = NSData(contentsOfFile: audioPath)
    let encryptedAudio = Encryption.encryptAudio(chatRoomId: chatRoomId, inputData: audio!)
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(audioFileName)
    var task : StorageUploadTask!
    task = storageRef.putData(encryptedAudio, metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        if error != nil {
            print("upload audio error \(error!.localizedDescription)")
            return
        }
        storageRef.downloadURL(completion: { (url, error) in
            guard let downloadUrl = url else {
                compleltion(nil)
                return
                
            }
            compleltion(downloadUrl.absoluteString)
        })
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
    
}

func downloadAudio(audioUrl: String, chatRoomId: String, completion: @escaping(_ audioFileName: String) -> Void) {
    
    let audioURL = NSURL(string: audioUrl)
    
    let audioFileName = (audioUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    
    if fileExistAtPath(path: audioFileName) {
        completion(audioFileName)
    } else {
        let downloadQueue = DispatchQueue(label: "audioDownloadQueue")
        
        downloadQueue.async {
            
            let data = NSData(contentsOf: audioURL! as URL)
            if data != nil {
                var docURL = getDocumentsURL()
                let decryptedData = Encryption.decryptAudio(chatRoomId: chatRoomId, encryptedData: data!)
                docURL = docURL.appendingPathComponent(audioFileName, isDirectory: false)
                decryptedData.write(to: docURL, atomically: true)
                
                DispatchQueue.main.async {
                    completion(audioFileName)
                }
            } else {
                DispatchQueue.main.async {
                    print("no audio in database")
                    
                }
            }
        }
    }
    
}




//Helpers

func videoThumbnail(video: NSURL) -> UIImage {
    let asset = AVURLAsset(url: video as URL, options: nil)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    var image : CGImage?
    do {
        image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
    } catch let error as NSError {
        print(error.localizedDescription)
    }
    let thumbnail = UIImage(cgImage: image!)
    return thumbnail
}

func fileInDocumentsDirectory(fileName: String) -> String {
    let fileURL = getDocumentsURL().appendingPathComponent(fileName)
    
    return fileURL.path
}

func getDocumentsURL() -> URL {
    let decumentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    return decumentURL!
}

func fileExistAtPath(path: String) -> Bool {
    
    var doesExist = false
    
    let filePath = fileInDocumentsDirectory(fileName: path)
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: filePath) {
        doesExist = true
    } else {
        doesExist = false
    }
    
    return doesExist
}
