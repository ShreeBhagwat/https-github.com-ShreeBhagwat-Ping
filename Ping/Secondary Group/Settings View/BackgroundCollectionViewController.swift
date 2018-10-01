//
//  BackgroundCollectionViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 16/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import ProgressHUD

private let reuseIdentifier = "Cell"

class BackgroundCollectionViewController: UICollectionViewController {
    var backgrounds: [UIImage] = []
    let userDefaults = UserDefaults.standard
    
    private let imageNamesArray = ["1", "2", "3", "5"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        } else {
            // Fallback on earlier versions
        }
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(self.resetToDefaults))
        self.navigationItem.rightBarButtonItem = resetButton
        setupImageArray()
}

   
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return backgrounds.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BackgroundCollectionViewCell
        cell.generateCell(image: backgrounds[indexPath.row])
    
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        userDefaults.set(imageNamesArray[indexPath.row], forKey: kBACKGROUBNDIMAGE)
        userDefaults.synchronize()
        
        ProgressHUD.showSuccess("Background Set")
        
        
    }
    
    // MARK: IB Actions
    @objc func resetToDefaults(){
        userDefaults.removeObject(forKey: kBACKGROUBNDIMAGE)
        userDefaults.synchronize()
        ProgressHUD.showSuccess("Reset Done")
    }
    // MARK: Helpers
    func setupImageArray(){
        for imageName in imageNamesArray {
            let image = UIImage(named: imageName)
            if image != nil {
                backgrounds.append(image!)
            }
        }
    }
}

