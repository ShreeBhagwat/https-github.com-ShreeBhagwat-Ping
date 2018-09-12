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

// Image

func uploadImage(image: UIImage, chatroomId: String, view: UIView, complition: @escaping (_ imageLink: String?) -> Void) {
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    let dateString = dateFormatter().string(from: Date())
    let photoFileName = "PictureMessage/" + FUser.currentId() + "/" + chatroomId + "/" + dateString + ".jpg"
    let storageReference = storage.reference(forURL: kFILEREFERENCE).child(photoFileName)
    let imageData = image.jpegData(compressionQuality: 0.5)
    var task: StorageUploadTask!
    
    task = storageReference.putData(imageData!, metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        if error != nil {
            print("Error uploading Image \(error?.localizedDescription)")
            return
        }
        storageReference.downloadURL(completion: { (url, error) in
            guard let downloadUrl = url else {
                complition(nil)
                return
            }
            complition(downloadUrl.absoluteString)
        })
    })
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}

func downloadImage(imageURl: String, completion: @escaping(_ image: UIImage?) -> Void) {
    
    let imageUrl = NSURL(string: imageURl)
        print(imageURl)
    let imageFileName = (imageURl.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    print(imageFileName)
    
    if fileExistsAtPath(path: imageFileName) {
        // Exists
        print("Image File  Exists")
        print(imageFileName)
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(fileName: imageFileName)) {
            completion(contentsOfFile)
        }else {
            print("Could Not generate image")
            completion(nil)
        }
    }else {
        // Does not Exists
        print("Image File Does Not Exists")
        
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: imageUrl! as URL)
            if data != nil {
                var docUrl = getDocumentsURL()
               docUrl =  docUrl.appendingPathComponent(imageFileName, isDirectory: false)
                
                data!.write(to: docUrl, atomically: true)
             
                let imageToReturn = UIImage(data: data! as Data)
                DispatchQueue.main.async {
                    completion(imageToReturn!)
                    print("Image Saved locally")
                }
            } else {
                DispatchQueue.main.async {
                    print("No Image In DataBase")
                    completion(nil)
                }
            }
        }
    }
    
}
// Upload Video Func
func uploadVideo(video: NSData, chatroomId: String, view: UIView, completion: @escaping(_ videoLink: String?) -> Void){
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    
    let dateString = dateFormatter().string(from: Date())
    let videoFileName = "VideoMessage/" + FUser.currentId() + "/" + chatroomId + "/" + dateString + ".mov"
    
    let storageReference = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)
    var task: StorageUploadTask!
    task = storageReference.putData(video as Data, metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            print("Could not upload video\(error?.localizedDescription)")
            return
        }
        storageReference.downloadURL(completion: { (url, error) in
            guard let downloadURL = url else {
                completion(nil)
                return
            }
            completion(downloadURL.absoluteString)
        })
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
        
    }
}

// Download Video

func downloadVideo(videoURL: String, completion: @escaping(_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
    
    let videoUrl = NSURL(string: videoURL)
    
    let videoFileName = (videoURL.components(separatedBy: "%").last!).components(separatedBy: "?").first!
    
    if fileExistsAtPath(path: videoFileName) {
        // Exists
        completion(true, videoFileName)
      
    }else {
        // Does not Exists
        print("Image File Does Not Exists")
        let downloadQueue = DispatchQueue(label: "videoDownloadQueue")
        downloadQueue.async {
            let data = NSData(contentsOf: videoUrl! as URL)
            if data != nil {
                var docUrl = getDocumentsURL()
                docUrl =  docUrl.appendingPathComponent(videoFileName, isDirectory: false)
                
                data!.write(to: docUrl, atomically: true)
                DispatchQueue.main.async {
                    completion(true, videoFileName)
                    
                }
            } else {
                DispatchQueue.main.async {
                    print("No video In DataBase")
                    
                }
            }
        }
    }
    
}

// Helper Function

func videoThumbnail(video: NSURL) -> UIImage {
    let asset = AVURLAsset(url: video as URL, options: nil)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTime(seconds: 0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image: CGImage?
    
    do {
        image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
        print("image created successfully")
    }
    catch let error  as NSError{
        print(error.localizedDescription)
    }
    
    let thumbnail = UIImage(cgImage: image!)
    
    return thumbnail
}


func fileInDocumentsDirectory(fileName: String) -> String {
   let fileUrl = getDocumentsURL().appendingPathComponent(fileName)
    return fileUrl.path
    
}

func getDocumentsURL() -> URL {
   let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    return documentUrl!
}

func fileExistsAtPath(path: String) -> Bool {
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

