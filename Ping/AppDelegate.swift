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
import PushKit
import FirebaseFirestore
import FirebaseDatabase
import ProgressHUD


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate , SINClientDelegate, SINCallClientDelegate, SINManagedPushDelegate, PKPushRegistryDelegate {
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
    }
    
    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?
    
    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?
    
    var _client: SINClient!
    var push: SINManagedPush!
    var callKitProvider: SINCallKitProvider!
    var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if Reachability.isConnectedToNetwork(){
            
        }else{
            ProgressHUD.showError("No Connection")
        }
        
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        
        //AutoLogin
        authListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
            
            Auth.auth().removeStateDidChangeListener(self.authListener!)
            
            if user != nil {
                
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil {
                    
                    DispatchQueue.main.async {
                        self.goToApp()
                        
                    }
                }
            }
        })
        
        self.push = Sinch.managedPush(with: .development)
        self.push.delegate = self
        self.push.setDesiredPushTypeAutomatically()
        
        func userDidLogin(userId: String) {
            
            self.push.registerUserNotificationSettings()
            self.initSinchWithUserId(userId: userId)
            self.startOneSignal()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil) { (note) in
            
            let userId = note.userInfo![kUSERID] as! String
            UserDefaults.standard.set(userId, forKey: kUSERID)
            UserDefaults.standard.synchronize()
            
            userDidLogin(userId: userId)
        }
        
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { (granted, error) in
            })
            application.registerForRemoteNotifications()
        } else {
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID, handleNotificationReceived: nil, handleNotificationAction: nil, settings: [kOSSettingsKeyInAppAlerts : false])
        
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        var top = self.window?.rootViewController
        
        while top?.presentedViewController != nil {
            top = top?.presentedViewController
        }
        
        if top! is UITabBarController {
            setBadge(controller: top as! UITabBarController)
        }
        
        
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : "online"]) { (success) in
            }
        }
        
        locationManagerStart()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        recentBadgeHandler?.remove()
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : "offline"]) { (success) in
                
            }
        }
        
        locationMangerStop()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        if callKitProvider != nil {
            let call = callKitProvider.currentEstablishedCall()
            
            if call != nil {
                var top = self.window?.rootViewController
                
                while (top?.presentedViewController != nil) {
                    top = top?.presentedViewController
                }
                
                
                if !(top! is CallViewController) {
                    let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
                    
                    callVC._call = call
                    
                    top?.present(callVC, animated: true, completion: nil)
                }
            }
        }
        // If there is one established call, show the callView of the current call when the App is brought to foreground.
        // This is mainly to handle the UI transition when clicking the App icon on the lockscreen CallKit UI.
        
    }
    
    
    
    
    //MARK: GoToApp
    
    func goToApp() {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.window?.rootViewController = mainView
    }
    
    
    //MARK: PushNotification functions
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        //        self.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        Auth.auth().setAPNSToken(deviceToken, type:AuthAPNSTokenType.sandbox)
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("rem not with fetch")
        
        let firebaseAuth = Auth.auth()
        if (firebaseAuth.canHandleNotification(userInfo)){
            return
        } else {
            //            self.push.application(application, didReceiveRemoteNotification: userInfo)
        }
        
    }
    
    ////     new code
    //    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
    //        print("did rec rem not")
    //
    ////        self.push.application(application, didReceiveRemoteNotification: userInfo)
    //    }
    //    //end of new code
    
    
    //MARK: Location manger
    
    func locationManagerStart() {
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager!.requestWhenInUseAuthorization()
        }
        
        locationManager!.startUpdatingLocation()
    }
    
    func locationMangerStop() {
        
        if locationManager != nil {
            locationManager!.stopUpdatingLocation()
        }
    }
    
    //MARK: Location Manager delegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("faild to get location")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted:
            print("restricted")
        case .denied:
            locationManager = nil
            print("denied location access")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        coordinates = locations.last!.coordinate
    }
    
    
    //MARK: OneSignal
    
    func startOneSignal() {
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        
        let userID = status.subscriptionStatus.userId
        let pushToken = status.subscriptionStatus.pushToken
        
        if pushToken != nil {
            if let playerID = userID {
                UserDefaults.standard.set(playerID, forKey: kPUSHID)
            } else {
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
            UserDefaults.standard.synchronize()
        }
        
        //updateOneSignalId
        updateOneSignalId()
    }
    
    
    //MARK: Sinch
    
    func initSinchWithUserId(userId: String) {
        
        if _client == nil {
            
            _client = Sinch.client(withApplicationKey: kSINCHKEY, applicationSecret: kSINCHSECRET, environmentHost: "sandbox.sinch.com", userId: userId)
            
            _client.delegate = self
            _client.call()?.delegate = self
            
            _client.setSupportCalling(true)
            _client.enableManagedPushNotifications()
            //            _client.setPushNotificationDisplayName(FUser.currentUser()?.fullname)
            _client.start()
            _client.startListeningOnActiveConnection()
            
            callKitProvider = SINCallKitProvider(withClient: _client)
        }
    }
    
    //MARK: SinchManagedPushDelegate
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        print("managed push")
        if pushType == "PKPushTypeVoIP" {
            self.handleRemoteNotification(userInfo: payload as NSDictionary)
        }
    }
    
    func handleRemoteNotification(userInfo: NSDictionary) {
        print("got rem not")
        if _client == nil {
            if let userId = UserDefaults.standard.object(forKey: kUSERID) {
                self.initSinchWithUserId(userId: userId as! String)
            }
        }
        
        let result = self._client.relayRemotePushNotification(userInfo as! [AnyHashable : Any])
        
        if result!.isCall() {
            print("handle call notification")
        }
        
        if result!.isCall() && result!.call()!.isCallCanceled {
            self.presentMissedCallNotificationWithRemoteUserId(userId: result!.call()!.callId)
        }
        
    }
    
    func presentMissedCallNotificationWithRemoteUserId(userId: String) {
        
        if UIApplication.shared.applicationState == .background {
            
            let center = UNUserNotificationCenter.current()
            
            let content = UNMutableNotificationContent()
            content.title = "Missed Call"
            content.body = "From \(userId)"
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(identifier: "ContentIdentifier", content: content, trigger: trigger)
            
            center.add(request) { (error) in
                
                if error != nil {
                    print("error on notification", error!.localizedDescription)
                }
            }
        }
    }
    
    //MARK: SinchCallClientDelegate
    
    func client(_ client: SINCallClient!, willReceiveIncomingCall call: SINCall!) {
        print("will receive")
        callKitProvider.reportNewIncomingCall(call: call)
    }
    
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        
        print("........did receive call")
        
        //present call view
        var top = self.window?.rootViewController
        
        while (top?.presentedViewController != nil) {
            top = top?.presentedViewController
        }
        
        let callVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallVC") as! CallViewController
        
        callVC._call = call
        top?.present(callVC, animated: true, completion: nil)
    }
    
    //MARK:  SinchClintDelegate
    
    func clientDidStart(_ client: SINClient!) {
        print("Sinch did start")
    }
    
    func clientDidStop(_ client: SINClient!) {
        print("Sinch did stop")
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        print("Sinch did fail \(error.localizedDescription)")
    }
    
    
}

