//
//  CallViewController.swift
//  Ping
//
//  Created by Gauri Bhagwat on 22/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit

class CallViewController: UIViewController, SINCallDelegate {

    // MARK: Connections
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var muteButtonOutlet: UIButton!
    @IBOutlet weak var speakerButtonOutlet: UIButton!
    @IBOutlet weak var answerButtonOutlet: UIButton!
    @IBOutlet weak var endCallButtonOutlet: UIButton!
    @IBOutlet weak var declineButtonOutlet: UIButton!
    
    // MARK: Var
    var speaker = false
    var mute = false
    var durationTimer : Timer! = nil
    var _call: SINCall!
    var callAnswer = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: VIEW Function
    override func viewWillAppear(_ animated: Bool) {
        userNameLabel.text = "Unknown"
        let id = _call.remoteUserId
        
        getUsersFromFirestore(withIds: [id!]) { (allUser) in
            if allUser.count > 0 {
                let user = allUser.first!
                self.userNameLabel.text = user.fullname
                
                imageFromData(pictureData: user.avatar, withBlock: { (avatarImage) in
                    if avatarImage != nil {
                        self.avatarImageView.image = avatarImage!.circleMasked
                    }
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _call.delegate = self
        if _call.direction == SINCallDirection.incoming {
            // Show Buttons
            showButton()
            audioController().startPlayingSoundFile(pathForSound(soundName: "incoming"), loop: true)
            
        } else {
            callAnswer = true
            // show Buttons
            setCallStatus(text: "Calling...")
            showButton()
        }
        
    }
    
    func audioController() -> SINAudioController {
        return appDelegate._client.audioController()
    }
    
    func setCall(call: SINCall) {
        _call = call
        _call.delegate = self
        
    }
    


    // MARK: IBActions
    
    @IBAction func muteButtonPressed(_ sender: Any) {
        if mute {
            mute = false
            audioController().unmute()
            muteButtonOutlet.setImage(UIImage(named: "mute"), for: .normal)
            
        }else {
            mute = true
            audioController().mute()
            muteButtonOutlet.setImage(UIImage(named: "muteSelected"), for: .normal)
        }
    }
    
    @IBAction func speakerButtonPressed(_ sender: Any) {
        
        if !speaker {
            speaker = true
            audioController().enableSpeaker()
            speakerButtonOutlet.setImage(UIImage(named: "speakerSelected"), for: .normal)
        }else{
            speaker = false
            audioController().disableSpeaker()
            speakerButtonOutlet.setImage(UIImage(named: "speaker"), for: .normal)
        }
    }
    
    
    @IBAction func answerButtonPressed(_ sender: Any) {
        callAnswer = true
        showButton()
        audioController().stopPlayingSoundFile()
        _call.answer()
        
    }
    
    @IBAction func hangupButtonPressed(_ sender: Any) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func declineButtonPressed(_ sender: Any) {
        _call.hangup()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: SINCall Delegates
    
    func callDidProgress(_ call: SINCall!) {
        setCallStatus(text: "Ringing...")
        audioController().startPlayingSoundFile(pathForSound(soundName: "ringback"), loop: true)
    }
    
    func callDidEstablish(_ call: SINCall!) {
        // StartTimer
        startCallDurationTimer()
        showButton()
        audioController().stopPlayingSoundFile()
        
        
    }
    
    func callDidEnd(_ call: SINCall!) {
        audioController().stopPlayingSoundFile()
        // Stop Call timer
        stopCallDurationTimer()
        self.dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: Timer
    
    @objc func onDuration(){
        let duration = Date().timeIntervalSince(_call.details.establishedTime)
        // UpdateTime label
        updateTimerLabel(seconds: Int(duration))
    }
    
    func updateTimerLabel(seconds: Int) {
        let min = String(format: "%02d", (seconds / 60))
        let sec = String(format: "%02d", (seconds % 60))
        setCallStatus(text: "\(min) : \(sec)")
    }
    
    func startCallDurationTimer(){
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.onDuration), userInfo: nil, repeats: true)
        
    }
    
    func stopCallDurationTimer(){
        if durationTimer != nil {
            durationTimer.invalidate()
            durationTimer = nil
        }
    }
    
    
    
    
    // MARK Update UI
    func setCallStatus(text: String){
        statusLabel.text = text
    }
    func showButton(){
        if callAnswer {
            declineButtonOutlet.isHidden = true
            endCallButtonOutlet.isHidden = false
            answerButtonOutlet.isHidden = true
            muteButtonOutlet.isHidden = false
            speakerButtonOutlet.isHidden = false
        }else {
            declineButtonOutlet.isHidden = false
            endCallButtonOutlet.isHidden = true
            answerButtonOutlet.isHidden = false
            muteButtonOutlet.isHidden = true
            speakerButtonOutlet.isHidden = true
        }
    }
    
    // MARK: HElperFunc
    
    func pathForSound(soundName: String) -> String {
        return Bundle.main.path(forResource: soundName, ofType: "wav")!
    }
    
}
