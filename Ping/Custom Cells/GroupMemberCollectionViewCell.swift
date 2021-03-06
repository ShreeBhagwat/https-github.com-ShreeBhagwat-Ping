//
//  GroupMemberCollectionViewCell.swift
//  Ping
//
//  Created by Gauri Bhagwat on 18/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
protocol GroupMemberCollectionViewCellDelegate {
    func didClickDeleteButton(indexPath: IndexPath)
}

class GroupMemberCollectionViewCell: UICollectionViewCell {
    var indexPath : IndexPath!
    var delegate: GroupMemberCollectionViewCellDelegate?
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    
    @IBOutlet weak var deleteButtonOutlet: UIButton!
    
    func generateCell(user: FUser, indexPath: IndexPath){
        self.indexPath = indexPath
        nameLabel.text = user.firstname
        
        if user.avatar != ""{
            imageFromData(pictureData: user.avatar) { (avatarImage) in
                if avatarImage != nil{
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        
    }
    
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        delegate!.didClickDeleteButton(indexPath: indexPath)
    }
    
}
