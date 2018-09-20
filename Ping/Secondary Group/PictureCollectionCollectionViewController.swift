//
//  PictureCollectionCollectionViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 14/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import IDMPhotoBrowser



class PictureCollectionCollectionViewController: UICollectionViewController {
    var allImages: [UIImage] = []
    var allImageLinks: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "All Pictures"
        
        if allImageLinks.count > 0 {
            // Download Images
            downloadImages()
        }
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allImages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mediaCell", for: indexPath) as! PictureCollectionViewCell
        
        cell.generateCell(image: allImages[indexPath.row])
    
        // Configure the cell
    
        return cell
    }
    
    // MARK:UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photos = IDMPhoto.photos(withImages: allImages)
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayDoneButton = false
        browser?.setInitialPageIndex(UInt(indexPath.row))
        self.present(browser!, animated: true, completion: nil)
    }

    var getTheChatRoomId = ""
    
    
    //MARK: Download Images
    
    func downloadImages() {
        for imageLink in allImageLinks {
            
            downloadImage(imageUrl: imageLink, chatRoomId: getTheChatRoomId) { (image) in
                if image != nil {
                    self.allImages.append(image!)
                    self.collectionView.reloadData()
                }
            }
        }
    }

}
