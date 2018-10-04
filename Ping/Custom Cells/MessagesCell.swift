//
//  MessagesCell.swift
//  Ping
//
//  Created by Gauri Bhagwat on 01/10/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController

class MessageViewOutgoing: JSQMessagesCollectionViewCellOutgoing {
    
    @IBOutlet weak var timeStamp: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override class func nib() -> UINib {
        return UINib (nibName: "MessageViewOutgoing", bundle: Bundle.main)
    }
    
    override class func cellReuseIdentifier() -> String {
        return "MessageViewOutgoing"
    }
    
    override class func mediaCellReuseIdentifier() -> String {
        return "MessageViewOutgoing_JSQMedia"
    }
    
}



class MessageViewIncoming: JSQMessagesCollectionViewCellIncoming {
    
    @IBOutlet weak var timeStamp: UILabel!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override class func nib() -> UINib {
        return UINib (nibName: "MessageViewIncoming", bundle: Bundle.main)
    }
    
    override class func cellReuseIdentifier() -> String {
        return "MessageViewIncoming"
    }
    
    override class func mediaCellReuseIdentifier() -> String {
        return "MessageViewIncoming_JSQMedia"
    }
}


