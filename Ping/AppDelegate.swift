//
//  AppDelegate.swift
//  Ping
//
//  Created by Gauri Bhagwat on 30/08/18.
//  Copyright © 2018 Development. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var authListner: AuthStateDidChangeListenerHandle?
    
    var locationManager: CLLocationManager?
    var cordinates: CLLocationCoordinate2D?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        //Auto Login
        authListner = Auth.auth().addStateDidChangeListener({ (auth, user) in
            Auth.auth().removeStateDidChangeListener(self.authListner!)
            
            if user != nil {
                
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil {
                    DispatchQueue.main.async {
                        self.goToApp()
                    }
                }
            }
        })
        func userDidLogin(userId: String){
            self.startOneSignal()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil) { (notification) in
            let userId = notification.userInfo![kUSERID] as! String
            UserDefaults.standard.set(userId, forKey: kUSERID)
            UserDefaults.standard.synchronize()
            print("User has Logged in .........................")
            userDidLogin(userId: userId)
        }
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID)
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : true]) { (sucess) in
                
            }
        }
        
        
        locationManagerStart()
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : false]) { (sucess) in
            }
            }
        locationManagerStop()
    }
    
    //Mark GoToApp
    func goToApp(){
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID: FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.window?.rootViewController = mainView
    }
    
        // MARK: Location Manager
    func locationManagerStart(){
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager!.requestWhenInUseAuthorization()
            
        }
        
        locationManager!.startUpdatingLocation()
    }
    func locationManagerStop(){
        if locationManager != nil {
            locationManager!.stopUpdatingLocation()
        }
    }

    // MARK: Location Manager delegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("failed to get location ")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .authorizedAlways:
            manager.stopUpdatingLocation()
        case .restricted:
            print("Location restricted for now")
        case .denied:
            locationManager = nil
            print("denied location permission ")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        cordinates = locations.last!.coordinate
    }
    // MARK: One Signal
    func startOneSignal(){
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let userId = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil {
            if let playerId = userId {
                UserDefaults.standard.set(playerId, forKey: kPUSHID)
                
            } else {
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
            UserDefaults.standard.synchronize()
        }
        // Update One Signal ID
        updateOneSignalId()
        
    }
}

