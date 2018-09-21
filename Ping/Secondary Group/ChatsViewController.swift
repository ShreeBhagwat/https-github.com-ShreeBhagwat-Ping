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

class ChatsViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IQAudioRecorderViewControllerDelegate {
  let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    //MARK: Assign Variables
    var chatroomId: String!
    var membersId: [String]!
    var membersToPush: [String]!
    var titleName: String!
    var newChatListner: ListenerRegistration?
    var typingListner: ListenerRegistration?
    var typingCounter = 0
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
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatar = true
    var firstLoad: Bool?
    
    
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
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatroomId)
    }
    override func viewWillDisappear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatroomId)
    }
    
    //layout Fix for iphone X
    override func viewDidLayoutSubviews() {
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
    // End Of layout Fix iphone X

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createTypingObserver()
        loadUserDefaults()
        
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        } else {
            // Fallback on earlier versions
        }
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        if isGroup! {
            getCurrentGroup(withId: chatroomId)
        }
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        jsqAvatarDictionary = [ : ]
        
        
        setCustomTitle()
        loadMessages()
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()?.firstname
        
        //layout Fix for iphone X
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        
        constraint.priority = UILayoutPriority(rawValue: 1000)
        if #available(iOS 11.0, *) {
            self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            // Fallback on earlier versions
        }
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {

        let message = messages[indexPath.row]
        var avatar: JSQMessageAvatarImageDataSource

        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId){
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)


        }
        return avatar
    }
    
    
    // MARK: JSQ-MessageDelegate
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        // Creating Alert Menu Buttons
        
        let camera = Camera(delegate_: self)
        let actionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            camera.PresentMultyCamera(target: self, canEdit: false)
        }
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        let shareVideo  = UIAlertAction(title: "Video Lbrary", style: .default) { (action) in
            camera.PresentVideoLibrary(target: self, canEdit: false)
        }
        let shareLocation = UIAlertAction(title: "Location", style: .default) { (action) in
            if self.haveAccessToUserLocation() {
                self.sendMessages(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
            }
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
           let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
        }
    }
    
    // LoadEarlier Button
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        // LOADMORE MESSAGES
        self.loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minMessagesNumber)
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let  messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        switch messageType {
        case kPICTURE:
            let message = messages[indexPath.row]
            let mediaItem = message.media as! JSQPhotoMediaItem
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            let browser = IDMPhotoBrowser(photos: photos)
            self.present(browser!, animated: true, completion: nil)
            
        case kLOCATION:
            let message = messages[indexPath.row]
            let mediaItem = message.media as! JSQLocationMediaItem
            let mapView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mapViewController") as! MapViewController
            mapView.location = mediaItem.location
            self.navigationController?.pushViewController(mapView, animated: true)
        case kVIDEO:
           
            let message = messages[indexPath.row]
            let mediaItem = message.media as! VideoMessage
            let player =  AVPlayer(url: mediaItem.fileURL! as URL)
            let moviePlayer = AVPlayerViewController()
            let session = AVAudioSession.sharedInstance()
            
            try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            moviePlayer.player = player
            self.present(moviePlayer, animated: true) {
                moviePlayer.player!.play()
            }
            
        default:
            print("Unkown message Tapped")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        
        let senderId = messages[indexPath.row].senderId
        var selectUser: FUser?
        
        if senderId == FUser.currentId() {
            selectUser = FUser.currentUser()
        } else {
            for user in withUsers {
                if user.objectId == senderId {
                    selectUser = user
                }
            }
        }
        // Show User Profile
        presentUserProfile(forUser: selectUser!)
    }
    // MARK: Delet For MultiMedia Message
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if messages[indexPath.row].isMediaMessage {
            if action.description == "delete:"{
                return true
            } else{
                return false
                
            }
        }else{
            if action.description == "delete:" || action.description == "copy:" {
                return true
            }else{
                return false
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        let messageId = objectMessages[indexPath.row][kMESSAGEID] as! String
        objectMessages.remove(at: indexPath.row)
        messages.remove(at: indexPath.row)
        
        // Deleting a Message From Firebase
        OutgoingMessages.deleteMessage(withId: messageId, chatroomId: self.chatroomId)
    }
    
    
    // MARK: Send Messages
    
    func sendMessages(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?){
        var outgoingMessage: OutgoingMessages?
        let currentUsers = FUser.currentUser()!
        
        //TEXT MESSAGE
        if let text = text {
            let encryptedText = Encryption.encryptText(chatRoomId: chatroomId, message: text)
            outgoingMessage = OutgoingMessages.init(message: encryptedText, senderId: currentUsers.objectId, senderName: currentUsers.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        // PICTURE MESSAGE
        if let pic = picture {
            uploadImage(image: pic, chatRoomId: chatroomId, view: self.navigationController!.view) { (imageLink) in
                if imageLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatroomId, message: "[\(kPICTURE)]")
                   let encryptedImage = Encryption.encryptImages(chatRoomId: self.chatroomId, image: pic)
                    
                    outgoingMessage = OutgoingMessages(message: encryptedText, pictureLink: imageLink!, senderId: currentUsers.objectId, senderName: currentUsers.fullname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage!.sendMessage(chatroomId: self.chatroomId, messageDictionary: outgoingMessage!.messageDictionary, membersId: self.membersId, membersToPush: self.membersToPush)
                }
            }
            return
        }
        
        // Video Message
        if let video = video {
            let videoData = NSData(contentsOfFile: video.path!)
            
            // Generate ThumbNail
            let thumbnail = videoThumbnail(video: video)
            let dataThumbnail = thumbnail.jpegData(compressionQuality: 0.3)
            // UploadVideo
            
            uploadVideo(video: videoData!, chatRoomId: chatroomId, view: self.navigationController!.view) { (videoLink) in
                if videoLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatroomId, message: "[\(kVIDEO)]")
                   
                    
                    outgoingMessage = OutgoingMessages(message: encryptedText, video: videoLink!, thumbnail: dataThumbnail! as NSData, senderId: currentUsers.objectId, senderName: currentUsers.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage!.sendMessage(chatroomId: self.chatroomId, messageDictionary: outgoingMessage!.messageDictionary, membersId: self.membersId, membersToPush: self.membersToPush)
                    
                    
                }
            }
            return
        }
        
        //Send Audio
        if let audioPath = audio {
            uploadAudio(audioPath: audioPath, chatRoomId: chatroomId, view: (self.navigationController?.view)!) { (audioLink) in
                if audioLink != nil {
                    let encryptedText = Encryption.encryptText(chatRoomId: self.chatroomId, message: "[\(kAUDIO)]")
                   
                    
                    outgoingMessage = OutgoingMessages(message: encryptedText, audioLink: audioLink!, senderId: currentUsers.objectId, senderName: currentUsers.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage!.sendMessage(chatroomId: self.chatroomId, messageDictionary: outgoingMessage!.messageDictionary, membersId: self.membersId, membersToPush: self.membersToPush)
                }
            }
            return
        }
        
        // MARK: Send Location
        if location != nil {
            let latitude: NSNumber = NSNumber(value: appDelegate.cordinates!.latitude)
            let longitude: NSNumber = NSNumber(value: appDelegate.cordinates!.longitude)
            
            let encryptedText = Encryption.encryptText(chatRoomId: self.chatroomId, message: "[\(kLOCATION)]")
           
            
            outgoingMessage = OutgoingMessages(message: encryptedText, Latitude: latitude, Longitude: longitude, senderId: currentUsers.objectId, senderName: currentUsers.firstname, date: date, status: kDELIVERED, type: kLOCATION)
        }
        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.sendMessage(chatroomId: chatroomId, messageDictionary: outgoingMessage!.messageDictionary, membersId: membersId, membersToPush: membersToPush)
    }
    
    // MARK: Load Messages
    
    func loadMessages(){
        // Update message status
        updatedChatListner = reference(.Message).document(FUser.currentId()).collection(chatroomId).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {return}
            
            if !snapshot.isEmpty {
                snapshot.documentChanges.forEach({ (diff) in
                    if diff.type == .modified {
                        self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)
                    }
                })
            }
        })
        
        
        // Loading last 11 message first
        reference(.Message).document(FUser.currentId()).collection(chatroomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                // Initial loading is done, start listing to new chat
                self.intialLoadComplete = true
                self.listenForNewChats()
                return
                
            }
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents))as! NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            // Remove Coruppterd message
            self.loadedMessages = self.removeBadMessage(allMessages: sorted)
            self.insertMessages()
            self.finishReceivingMessage(animated: true)
            self.intialLoadComplete = true
            
            // Get Picture Messages
            self.getPictureMessage()
            
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
                                    self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                                    
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
                self.getPictureMessage()
                
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
            
            OutgoingMessages.updateMessage(withId: messageDictionary[kMESSAGEID] as! String, chatroomId: chatroomId, memberId: membersId)
            
        }
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatroomId)
        if message != nil {
            objectMessages.append(messageDictionary)
            messages.append(message!)
        }
        return isIncoming(messageDictionary: messageDictionary)
    }
    
    func updateMessage(messageDictionary: NSDictionary){
        for index in 0 ..< objectMessages.count {
            let temp = objectMessages[index]
            
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String{
                objectMessages[index] = messageDictionary
                self.collectionView!.reloadData()
            }
        }
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
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatroomId)
        
        objectMessages.insert(messageDictionary, at: 0)
        messages.insert(message!, at: 0)
    }
    
    // MARK: IBAction
    @objc func backAction(){
        clearRecentCounter(chatRoomId: chatroomId)
        removeListner()
//        self.navigationController?.popViewController(animated: true)
        if let viewController = navigationController?.viewControllers.first(where: {$0 is ChatViewController}) {
            navigationController?.popToViewController(viewController, animated: false)
        }
        
    }
    
    @objc func infoButtonPressed() {
       let mediaVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mediaView") as! PictureCollectionCollectionViewController
        mediaVC.getTheChatRoomId = chatroomId
        mediaVC.allImageLinks = allPictureMessages
        self.navigationController?.pushViewController(mediaVC, animated: true)
    }
    
    @objc func showGroup() {
        let groupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "groupView") as! GroupViewController
        groupVC.group = group!
        self.navigationController?.pushViewController(groupVC, animated: true)
    }
    
    @objc func showUserProfile() {
       
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        profileVC.user = withUsers.first!
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func presentUserProfile(forUser: FUser){
        let profileVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        profileVC.user = forUser
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // MARK: Typing Indicator
    func createTypingObserver(){
        typingListner = reference(.Typing).document(chatroomId).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {return}
            
            if snapshot.exists {
                for data in snapshot.data()! {
                    if data.key != FUser.currentId(){
                        let typing = data.value as! Bool
                        self.showTypingIndicator = typing
                        
                        if typing {
                            self.scrollToBottom(animated: true)
                        }
                    }
                }
            } else {
                reference(.Typing).document(self.chatroomId).setData([FUser.currentId(): false])
            }
        })
    }
    
    func typingCounterStart(){
        typingCounter += 1
        typingCounterSave(typing: true)
        self.perform(#selector(self.typingCounterStop), with: nil, afterDelay: 2.0)
    }
    
    @objc func typingCounterStop(){
       typingCounter -= 1
        
        if typingCounter == 0 {
            typingCounterSave(typing: false)
        }
    }
    
    func typingCounterSave(typing: Bool){
        reference(.Typing).document(chatroomId).updateData([FUser.currentId(): typing])
    }
    // MARK: UI textView delegate
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        typingCounterStart()
        return true
    }

    
    // MARK: Custome Send Button
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
    // MARK: IQAudioDelegate
    
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        controller.dismiss(animated: true, completion: nil)
        self.sendMessages(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
        
    }
    
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: Update UI
    func setCustomTitle(){
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subtitle)
        
//        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        let infoButton = UIBarButtonItem(title: "All Media", style: .plain, target: self, action: #selector(self.infoButtonPressed))
        
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
            self.getAvatarImages()
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
    
    func setUpForGroupChat(){
        imageFromData(pictureData: (group![kAVATAR]) as! String) { (image) in
           if image != nil {
                self.avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        titleLabel.text = titleName
        subtitle.text = ""
    }
    
    
    // MARK: Get Avatart
    func getAvatarImages(){
        
        if showAvatar {
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
            
            // Get Current User Avatar
            avatarImageFrom(Fuser: FUser.currentUser()!)
            
            for user in withUsers {
                avatarImageFrom(Fuser: user)
            }
        }
    }
    
    func avatarImageFrom(Fuser: FUser){
        if Fuser.avatar != "" {
            dataImageFromString(pictureString: Fuser.avatar) { (imageData) in
                if imageData == nil {
                    return
                }
                
                if self.avatarImageDictionary != nil {
                    //Update Avatar If we have it
                    self.avatarImageDictionary!.removeObject(forKey: Fuser.objectId)
                    self.avatarImageDictionary!.setObject(imageData!, forKey: Fuser.objectId as NSCopying)
                } else {
                    self.avatarImageDictionary = [Fuser.objectId : imageData!]
                }
                // create JSQ avatar
                self.createJSQAvatars(avatarsDictionary: self.avatarImageDictionary)
                
            }
        }
    }
    
    func createJSQAvatars(avatarsDictionary: NSMutableDictionary?){
        let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        
        if avatarsDictionary != nil {
            
            for userId in membersId {
                if let avatarImagedata = avatarsDictionary![userId] {
                    let JSQAvatar  = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImagedata as! Data), diameter: 70)
                    
                    self.jsqAvatarDictionary!.setValue(JSQAvatar, forKey: userId)
                } else {
                    self.jsqAvatarDictionary!.setValue(defaultAvatar, forKey: userId)

                }
            }
            
            self.collectionView.reloadData()
           
        }
        
        
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessages(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: Location Access
    func haveAccessToUserLocation() -> Bool {
        if appDelegate.locationManager != nil {
            return true
        }else {
            ProgressHUD.showError("Please Give Access To Location In Settings")
            return false
        }
    }
    
    // MARK: Helper Function
    
    func loadUserDefaults(){
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(showAvatar, forKey: kSHOWAVATAR)
            
            userDefaults.synchronize()
        }
        showAvatar = userDefaults.bool(forKey: kSHOWAVATAR)
        checkForBackgroungImage()
    }
    
    func checkForBackgroungImage(){
        if userDefaults.object(forKey: kBACKGROUBNDIMAGE) != nil {
            self.collectionView.backgroundColor = .clear
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
            imageView.image = UIImage(named: userDefaults.object(forKey: kBACKGROUBNDIMAGE) as! String)!
            imageView.contentMode = .scaleAspectFill
            self.view.insertSubview(imageView, at: 0)
        }
    }
    
    func addNewPictureMessageLink(link: String){
        allPictureMessages.append(link)
    }
    
    func getPictureMessage(){
        allPictureMessages = []
        for message in loadedMessages {
            if message[kTYPE] as! String == kPICTURE {
                allPictureMessages.append(message[kPICTURE] as! String)
            }
            
        }
    }
    
    
    
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
    
    func removeListner(){
        if typingListner != nil {
            typingListner!.remove()
        }
        if newChatListner != nil {
            newChatListner!.remove()
        }
        if updatedChatListner != nil {
            updatedChatListner!.remove()
        }
    }
    
    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        let currentDateFormat = dateFormatter()
        currentDateFormat.dateFormat = "HH:mm"
        
        return currentDateFormat.string(from: date!)
    }
    
    func getCurrentGroup(withId: String){
        reference(.Group).document(withId).getDocument { (snapshot, error) in
            guard let snapshot = snapshot else {return}
            if snapshot.exists {
                self.group = snapshot.data() as! NSDictionary
                self.setUpForGroupChat()
            }
        }
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

