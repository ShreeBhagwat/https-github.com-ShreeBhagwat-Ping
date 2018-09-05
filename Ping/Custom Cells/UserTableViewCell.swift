//
//  UserTableViewCell.swift
//  Ping
//
//  Created by Gauri Bhagwat on 01/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate {
    func didTappedAvatarImage(indexPath : IndexPath)
}


class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    var indexPath : IndexPath!
    var delegate: UserTableViewCellDelegate?
    let tapGesture = UITapGestureRecognizer()
    
    override func awakeFromNib(){
        super.awakeFromNib()
        tapGesture.addTarget(self, action: #selector(self.avatarTapped))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func generateCellWith(fuser: FUser, indexPath: IndexPath) {
        
        self.indexPath = indexPath
        self.fullNameLabel.text = fuser.fullname
        
        if fuser.avatar != "" {
            imageFromData(pictureData: fuser.avatar) { (avatarImage) in
                
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    @objc func avatarTapped(){
        delegate?.didTappedAvatarImage(indexPath: indexPath)
    }

}
