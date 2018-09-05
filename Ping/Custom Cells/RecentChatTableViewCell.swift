//
//  RecentChatTableViewCell.swift
//  Ping
//
//  Created by Gauri Bhagwat on 05/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

protocol RecentChatTableViewCellDelegate {
    func didTappedAvatarImage(indexPath : IndexPath)
}

class RecentChatTableViewCell: UITableViewCell {

    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var counterView: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var counterBackground: UIView!
    
    var indexPath: IndexPath!
    let tapGesture = UITapGestureRecognizer()
    var delegate: RecentChatTableViewCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        counterBackground.layer.cornerRadius = counterBackground.frame.width/2
        tapGesture.addTarget(self, action: #selector(self.avatarTapped))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    // MARK: Generate Cell
    
    func generateCell(recentChat: NSDictionary, indexPath: IndexPath){
        self.indexPath = indexPath
        
        self.nameLabel.text = recentChat[kWITHUSERUSERNAME] as? String
        self.lastMessageLabel.text = recentChat[kLASTMESSAGE] as? String
        self.counterView.text = recentChat[kCOUNTER] as? String
   
        if let avatarString = recentChat[kAVATAR]{
            imageFromData(pictureData: avatarString as! String) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        if recentChat[kCOUNTER] as! Int != 0 {
            self.counterView.text = "\(recentChat[kCOUNTER] as! Int)"
            self.counterBackground.isHidden = false
            self.counterView.isHidden = false
        }else{
            self.counterBackground.isHidden = true
            self.counterView.isHidden = true
        }
        //Date Foramte
        var date: Date!
        if let created = recentChat[kDATE]{
            if (created as! String).count != 14 {
                date = Date()
            }else {
                date = dateFormatter().date(from: created as! String)!
            }
            
        } else {
            date = Date()
        }
        self.dateLabel.text = timeElapsed(date: date)
    }
    
    @objc func avatarTapped(){
        delegate!.didTappedAvatarImage(indexPath: indexPath)
    }
}
