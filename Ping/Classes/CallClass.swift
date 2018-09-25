//
//  CallClass.swift
//  Ping
//
//  Created by Gauri Bhagwat on 21/09/18.
//  Copyright © 2018 Development. All rights reserved.
//

import Foundation


class CallClass  {
    
    // MARK: Variables
    var objectId: String
    var callerId: String
    var callerFullName: String
    var withUserFullName: String
    var withUserId: String
    var status: String
    var isIncoming: Bool
    var callDate: Date
    
    init(_calledId: String, _withUserId: String, _callerFullName: String, _withUserFullName: String) {
        
       objectId = UUID().uuidString
       callerId = _calledId
       callerFullName = _callerFullName
       withUserFullName = _withUserFullName
       withUserId = _withUserId
       status = ""
       isIncoming = false
       callDate = Date()
    }
    
    init(_dicitionary: NSDictionary) {
        objectId = _dicitionary[kOBJECTID] as! String
        
        if let callId = _dicitionary[kCALLERID] {
            callerId = callId as! String
        } else {
            callerId = ""
        }
        if let withId = _dicitionary[kWITHUSERUSERID] {
            withUserId = withId as! String
        } else {
            withUserId = ""
        }
        if let callFullName = _dicitionary[kCALLERFULLNAME] {
            callerFullName = callFullName as! String
        } else {
            callerFullName = "Unknown"
        }
        if let withUserFName = _dicitionary[kWITHUSERFULLNAME]{
            withUserFullName = withUserFName as! String
        } else {
            withUserFullName = "Unknown"
        }
        if let callStatus = _dicitionary[kCALLSTATUS] {
            status = callStatus as! String
        }else {
            status = "Unknown"
        }
        if let incoming = _dicitionary[kISINCOMING] {
            isIncoming = true as! Bool
        } else {
            isIncoming = false
        }
        if let date = _dicitionary[kDATE]{
            if (date as! String).count != 14 {
                callDate = Date()
            } else {
                callDate = dateFormatter().date(from: date as! String)!
            }
        } else {
            callDate = Date()
        }
    }
    
    func dictionaryFromCall() -> NSDictionary {
        let dateString = dateFormatter().string(from: callDate)
        return NSDictionary(objects: [objectId, callerId, callerFullName, withUserId, withUserFullName, status, isIncoming, dateString ], forKeys: [kOBJECTID as NSCopying, kCALLERID as NSCopying, kCALLERFULLNAME as NSCopying, kWITHUSERUSERID as NSCopying, kWITHUSERFULLNAME as NSCopying, kSTATUS as NSCopying, kISINCOMING as NSCopying, kDATE as NSCopying])
    }
    
    //MARK: Save
    func saveCallInBackground(){
        // Caller
    reference(.Call).document(callerId).collection(callerId).document(objectId).setData(dictionaryFromCall() as! [String : Any])
        
        // Reciever
    reference(.Call).document(withUserId).collection(withUserId).document(objectId).setData(dictionaryFromCall() as! [String : Any])
    }
    
    //MARK: Delete
    func deleteCall(){
        reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).document(objectId).delete()
    }
    
}
