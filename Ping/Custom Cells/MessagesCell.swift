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
import ChameleonFramework

class ChatMessageCell: UICollectionViewCell {
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.text = "Sample Text For Now"
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = UIColor.clear
        tv.isEditable = false
        
        return tv
    }()

static let blueColour = UIColor(hexString: "78daf6")

let bubbleView: UIView = {
    let view = UIView()
    view.backgroundColor = blueColour
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 16
    view.layer.masksToBounds = true
    
    view.isUserInteractionEnabled = true
    
    return view
}()
    static let grayBubbleImage = UIImage(named: "bubble_gray")!.resizableImage(withCapInsets: UIEdgeInsets.init(top: 22, left: 26, bottom: 22, right: 26)).withRenderingMode(.alwaysTemplate)
    static let blueBubbleImage = UIImage(named: "bubble_blue")!.resizableImage(withCapInsets: UIEdgeInsets.init(top: 30 ,left: 36, bottom: 30, right: 36)).withRenderingMode(.alwaysTemplate)
    let bubbleImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = ChatMessageCell.grayBubbleImage
        imageView.tintColor = UIColor(white: 0.96, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profile")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    var messageTimeStamp: UILabel = {
        let messageTime = UILabel()
        messageTime.translatesAutoresizingMaskIntoConstraints = false
        messageTime.backgroundColor = UIColor.clear
        messageTime.font = UIFont.italicSystemFont(ofSize: 12)
        messageTime.layer.zPosition = 1
        messageTime.text = "00:00"
        
        return messageTime
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    var bubbleImageWidthAnchor: NSLayoutConstraint?
    var bubbleImageViewRightAnchor: NSLayoutConstraint?
    var bubbleImageViewLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    addSubview(bubbleView)
    addSubview(textView)
    addSubview(profileImageView)
    addSubview(messageTimeStamp)
    bubbleView.addSubview(bubbleImageView)
 
    //x,y,w,h
    profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
    profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
    profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
    
    
    //IOS 9 Constraints: x, y , width, height
    bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor)
    bubbleViewRightAnchor?.isActive = true
    bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
    bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
    bubbleWidthAnchor?.isActive = true
    bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    
    //BubbleImageView
    //Constraints:

    
    bubbleImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
    bubbleImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
    bubbleImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
    bubbleImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
    
    //IOS 9 Constraints: x, y , width, height
    //        textView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    textView.leftAnchor.constraint(equalTo: bubbleImageView.leftAnchor, constant: 10).isActive = true
    textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    textView.rightAnchor.constraint(equalTo: bubbleImageView.rightAnchor , constant: -10).isActive = true
    //        textView.widthAnchor.constraint(equalToConstant: 200).isActive = true
    textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

    messageTimeStamp.bottomAnchor.constraint(equalTo: textView.bottomAnchor,constant: -10).isActive = true
    messageTimeStamp.rightAnchor.constraint(equalTo: bubbleImageView.rightAnchor,constant: -15).isActive = true
    messageTimeStamp.topAnchor.constraint(equalTo: textView.bottomAnchor)
    //            messageTimeStamp.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
}

required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}
    
}






