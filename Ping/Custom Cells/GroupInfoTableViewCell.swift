//
//  GroupInfoTableViewCell.swift
//  Ping
//
//  Created by Gauri Bhagwat on 27/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

class GroupInfoTableViewCell: UITableViewCell {
    
    // MARK: CONNECTIONS
    
    @IBOutlet weak var avatarImageOutlet: UIImageView!
    @IBOutlet weak var userFullNameOutlet: UILabel!
    @IBOutlet weak var userStatusLabelOutlet: UILabel!
    
    //
    var indexPath : IndexPath!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func generateCell(user: FUser, indexPath: IndexPath){
        self.indexPath = indexPath
        userFullNameOutlet.text = user.firstname
    
        
        
        if user.avatar != ""{
            imageFromData(pictureData: user.avatar) { (avatarImage) in
                if avatarImage != nil{
                    self.avatarImageOutlet.image = avatarImage!.circleMasked
                }
            }
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
