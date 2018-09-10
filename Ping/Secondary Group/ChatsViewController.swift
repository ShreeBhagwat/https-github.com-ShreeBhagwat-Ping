//
//  ChatsViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 06/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import ChameleonFramework
import FirebaseFirestore

class ChatsViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Assign Variables
    var chatroomId: String!
    var membersId: [String]!
    var membersToPush: [String]!
    var titleName: String!
    var newChatListner: ListenerRegistration?
    var typingListner: ListenerRegistration?
    var updatedChatListner: ListenerRegistration?
    var isGroup: Bool?
    var group: NSDictionary?
    var withUsers: [FUser] = []
    
    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kPICTURE, kLOCATION]
    
    var maxMessagesNumber = 0
    var minMessagesNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessages: [NSDictionary] = []
    var allPictureMessages: [String] = []
    
    var intialLoadComplete = false
    
    
    
    var outGoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.flatSkyBlue())

    var incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor.flatGray())
    
    // MARK : Custome Header

    let leftBarButtonView : UIView = {
       let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    
    let avatarButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
            label.textAlignment = .left
        label.font = UIFont(name: label.font.fontName, size: 14)
        return label
    }()
    
    let subtitle: UILabel = {
       let label = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        label.textAlignment = .left
        label.font = UIFont(name: label.font.fontName, size: 14)
        return label
    }()
    
    
    
    
    
    //layout Fix for iphone X
    override func viewDidLayoutSubviews() {
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
    // End Of layout Fix iphone X

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        setCustomTitle()
        loadMessages()
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()?.firstname
        
        //layout Fix for iphone X
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        
        constraint.priority = UILayoutPriority(rawValue: 1000)
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        // End Of layout Fix iphone X
        // Custome Send Button
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        
    }
    
    // MARK: JSQMessage Delegate Function
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        // Set Text Colour
        if data.senderId == FUser.currentId() {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    // Display Message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
        
    }
    
    // Number of items In section (Telling collection view the number)
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // Creating Message Bubble For JSQ
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            return outGoingBubble
        }
        else {
            return incomingBubble
        }
        
    }
    
    // TimeHeading
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.row % 3 == 0 {
            let message = messages[indexPath.row]
            
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        }
            return nil
    }
    
    // Height For cell timeHeading
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.row % 3 == 0 {
            let message = messages[indexPath.row]
            
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    // Delivery Message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = objectMessages[indexPath.row]
        
        let status: NSAttributedString!
        let attributedStringColour = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
            status = NSAttributedString(string: statusText, attributes: attributedStringColour)
        default:
            status = NSAttributedString(string: "✔︎")
        }
        
        if indexPath.row == (messages.count - 1) {
            return status
        } else {
           return NSAttributedString(string: "")
        }
    }
    
    // Height For Delivery Message Status
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
    }
    
    
    
    // MARK: JSQ-MessageDelegate
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        // Creating Alert Menu Buttons
        
        let camera = Camera(delegate_: self)
        let actionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            print("Camera Action Pressed")
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        let shareVideo  = UIAlertAction(title: "Video Lbrary", style: .default) { (action) in
            print("Video Library button Pressed")
        }
        let shareLocation = UIAlertAction(title: "Location", style: .default) { (action) in
            print("Location Library button Pressed")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel button Pressed")
        }
        // Images For the actionMenu
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        // Adding Alerts To alert Controller
        actionMenu.addAction(takePhotoOrVideo)
        actionMenu.addAction(sharePhoto)
        actionMenu.addAction(shareVideo)
        actionMenu.addAction(shareLocation)
        actionMenu.addAction(cancelAction)
        
        
        // For Ipad Alert Controller
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverpresentationController = actionMenu.popoverPresentationController {
                currentPopoverpresentationController.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentationController.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentationController.permittedArrowDirections = .up
                self.present(actionMenu, animated: true, completion: nil)
                }
            }else {
                self.present(actionMenu, animated: true, completion: nil)
        }
  
    }
    
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if text != "" {
            self.sendMessages(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            updateSendButton(isSend: false)
        } else {
            print("Audio Message")
        }
    }
    
    // LoadEarlier Button
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        // LOADMORE MESSAGES
        self.loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minMessagesNumber)
        self.collectionView.reloadData()
    }
    
    
    // MARK: Send Messages
    
    func sendMessages(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?){
        var outgoingMessage: OutgoingMessages?
        let currentUsers = FUser.currentUser()!
        
        //TEXT MESSAGE
        if let text = text {
            outgoingMessage = OutgoingMessages.init(message: text, senderId: currentUsers.objectId, senderName: currentUsers.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        // PICTURE MESSAGE
        if let pic = picture {
            uploadImage(image: pic, chatroomId: chatroomId, view: self.navigationController!.view) { (imageLink) in
                if imageLink != nil {
                    let text = kPICTURE
                    
                    outgoingMessage = OutgoingMessages(message: text, pictureLink: imageLink!, senderId: currentUsers.objectId, senderName: currentUsers.fullname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage?.sendMessage(chatroomId: self.chatroomId, messageDictionary: outgoingMessage!.messageDictionary, membersId: self.membersId, membersToPush: self.membersToPush)
                }
            }
            return
        }
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.sendMessage(chatroomId: chatroomId, messageDictionary: outgoingMessage!.messageDictionary, membersId: membersId, membersToPush: membersToPush)
    }
    
    // MARK: Load Messages
    
    func loadMessages(){
        // Loading last 11 message first
        reference(.Message).document(FUser.currentId()).collection(chatroomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                // Initial loading is done, start listing to new chat
                self.intialLoadComplete = true
                return
                
            }
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents))as! NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            // Remove Coruppterd message
            self.loadedMessages = self.removeBadMessage(allMessages: sorted)
            self.insertMessages()
            self.finishReceivingMessage(animated: true)
            self.intialLoadComplete = true
            
            print("We Have Messages \(self.messages.count)")
            // Get Picture Messages
            
            // Get Old Messages In background
            
            // Start Listening for new Chats
            self.getOldMessagesInBackground()
            self.listenForNewChats()
            
        }
    }
    
    func listenForNewChats(){
        var lastMessageDate = "0"
        if loadedMessages.count > 0 {
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }

        newChatListner = reference(.Message).document(FUser.currentId()).collection(chatroomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {return}
            
            if !snapshot.isEmpty {
                for diff in snapshot.documentChanges{
                    if (diff.type == .added){
                        
                        let item = diff.document.data() as NSDictionary
                        if let type = item[kTYPE] {
                            if self.legitTypes.contains(type as! String){
                                //This is For Picture Message
                                if type as! String == kPICTURE {
                                    // add To Pictures
                                    
                                }
                                if self.insertInitialLoadedMessage(messageDictionary: item) {
                                    
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                self.finishReceivingMessage()
                            }
                        }
                        
                    }
                }
            }
        })
        
    }
    
    //Getting Old Messags in BackGround
    func getOldMessagesInBackground(){
        if loadedMessages.count > 10 {
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            reference(.Message).document(FUser.currentId()).collection(chatroomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else {return}
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                self.loadedMessages = self.removeBadMessage(allMessages: sorted) + self.loadedMessages
                
                // Get the picture messages
                
                self.maxMessagesNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessagesNumber = self.maxMessagesNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    
    // MARK: Insert Messages
    func insertMessages(){
        maxMessagesNumber = loadedMessages.count - loadedMessagesCount
        minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        
        if minMessagesNumber < 0 {
            minMessagesNumber = 0
        }
        
        for i in minMessagesNumber ..< maxMessagesNumber {
            let messageDictionary = loadedMessages[i]
            
          insertInitialLoadedMessage(messageDictionary: messageDictionary)
            
            loadedMessagesCount += 1
        }
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    
    func insertInitialLoadedMessage(messageDictionary: NSDictionary) -> Bool {
        // Check If Incomming
        let incomingMessage = IncomingMessages(collectionView_: self.collectionView)
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId(){
            //Update ReadMessage Status
            
        }
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatroomId: chatroomId)
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        return isIncoming(messageDictionary: messageDictionary)
    }
    
    // MARK: Load More Messages
    func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        if loadOld {
            maxMessagesNumber = minNumber - 1
            minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        }
        if minMessagesNumber < 0 {
            minMessagesNumber = 0
        }
        
        for i in (minMessagesNumber ... maxMessagesNumber).reversed() {
            let messageDictionary = loadedMessages[i]
            insertNewMessage(messageDictionary: messageDictionary)
            loadedMessagesCount += 1
        }
        loadOld = true
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func insertNewMessage(messageDictionary : NSDictionary) {
        let incomingMessage = IncomingMessages(collectionView_: self.collectionView!)
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatroomId: chatroomId)
        
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }
    
    // MARK: IBAction
    @objc func backAction(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func infoButtonPressed() {
        print("show Image MEssaage")
    }
    
    @objc func showGroup() {
        print("Show group")
    }
    
    @objc func showUserProfile() {
        print("Show profile")
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        profileVC.user = withUsers.first!
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // MARk: Custome Send Button
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }
    
    func updateSendButton(isSend: Bool){
        if isSend {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        }else {
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
        
    }
    //MARK: Update UI
    func setCustomTitle(){
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subtitle)
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        
        self.navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
        } else {
             avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        }
        
        getUsersFromFirestore(withIds: membersId) { (withUsers) in
            self.withUsers = withUsers
            //get avatars
            if !self.isGroup! {
                // Update User info
                self.setUIForSingleChat()
            }
        }
        
    }
    
    func setUIForSingleChat(){
        let withUser = withUsers.first!
        imageFromData(pictureData: withUser.avatar) { (avatarImage) in
            if avatarImage != nil {
                avatarButton.setImage(avatarImage!.circleMasked, for: .normal)
            }
        }
        titleLabel.text = withUser.fullname
        if withUser.isOnline {
            subtitle.text = "Online"
        }else{
            subtitle.text = "Offline"
        }
        
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessages(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: Helper Function
    func removeBadMessage(allMessages: [NSDictionary]) -> [NSDictionary]{
        var tempMessages = allMessages
        
        for message in tempMessages {
            if message[kTYPE] != nil {
                if !self.legitTypes.contains(message[kTYPE] as! String ) {
                    // Remove The message
                    tempMessages.remove(at: tempMessages.index(of: message)!)
                }
            }else {
                tempMessages.remove(at: tempMessages.index(of: message)!)
            }
        }
        return tempMessages
    }
    
    func isIncoming(messageDictionary: NSDictionary) -> Bool{
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        }
        return true
    }
    
    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        
        return currentDateFormat.string(from: date!)
    }
    


}
// MARK: Iphone X Layout FIX
extension JSQMessagesInputToolbar {
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else { return }
        if #available(iOS 11.0, *) {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
        }
    }
}
// End fix iPhone x
