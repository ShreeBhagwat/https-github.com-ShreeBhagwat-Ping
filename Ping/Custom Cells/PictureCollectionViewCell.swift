//
//  PictureCollectionViewCell.swift
//  Ping
//
//  Created by Gauri Bhagwat on 14/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

class PictureCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    func generateCell(image: UIImage) {
        self.imageView.image = image
    }
}
