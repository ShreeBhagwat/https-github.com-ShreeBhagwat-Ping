//
//  BackgroundCollectionViewCell.swift
//  Ping
//
//  Created by Gauri Bhagwat on 16/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

class BackgroundCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    func generateCell(image: UIImage){
        self.imageView.image = image
    }
}
