//
//  UserProfile.swift
//  ShadowsocksX-NG
//
//  Created by billphilip22 on 2019/1/22.
//  Copyright © 2019 qiuyuzhou. All rights reserved.
//

import Cocoa
import Alamofire

class UserProfile: NSObject {
    
    static let instance:UserProfile = UserProfile()
    
    var email:String = ""
    var pwd:String = ""
    var userToken:String?
    var userID:Int?
    var subLink:String?
    var profileMgr:ServerProfileManager!
    var baseURL:String = ""
    
    var delegate:UserProfileDelegate?
    
    fileprivate override init() {
        let defaults = UserDefaults.standard
        if let email = defaults.string(forKey: "UserMail") {
            self.email = email
        }
        
        if let pwd = defaults.string(forKey: "UserPwd") {
            self.pwd = pwd
        }
        
        if let baseURL = defaults.string(forKey: "baseURL") {
            self.baseURL = baseURL
        }
        
        profileMgr = ServerProfileManager.instance
    }
    
    
    fileprivate func sendRequest(url: String,
                                 parameters: [String:String],
                                 options: HTTPMethod,
                                 callback: @escaping ([String: Any]) -> Void) {
        
        Alamofire.request(url,
                          method: options,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: [:]).responseJSON{
                            response in
                            
                            if response.result.isSuccess {
                                callback(response.result.value! as! [String : Any])
                                
                            }
                            else{
                                callback([:])
                                self.pushNotification(title: "登录失败", subtitle: "", info: "发送到\(url)的请求失败，请检查您的网络")
                            }
        }
    }
    
    
    public func login(email:String, pwd:String, url:String) -> Void {
        let loginInfo =  ["email":email,"passwd":pwd]
        self.baseURL = url
        self.delegate?.didStartRequest()
        print("basrURL的地址是")
        print(self.baseURL)
        sendRequest(url: "\(baseURL)/api/token",
                    parameters: loginInfo,
                    options: HTTPMethod.post, callback: {resJson in
                        
                        self.delegate?.didFinishRequest()
                        
                        if let ret = resJson["ret"] as? Int{
                            if ret == 1{
                                let defaults = UserDefaults.standard
                                defaults.set(true, forKey: "UserLogIn")
                                
                                UserProfile.instance.email = email
                                UserProfile.instance.pwd = pwd
                                if let data = resJson["data"] as? NSDictionary {
                                    UserProfile.instance.userToken = data["token"] as? String
                                    UserProfile.instance.userID = data["user_id"] as? Int
                                }
                                
                                UserProfile.instance.save()
                                
                                //更新菜单
                                (NSApplication.shared().delegate as! AppDelegate).updateMainMenu()
                                
                                self.delegate?.didLogIn()
                                
                                self.updateServerByToken()
                            }else {
                                UserProfile.instance.email = email
                                UserProfile.instance.pwd = ""
                                
                                UserProfile.instance.save()
                                
                                self.delegate?.foundWrongLogInfo()
                                
                            }
                        }
        })
    }
    
    
    public func updateServerByToken() {
        func updateServerHandler(resJSON: [String:Any]) {
            //self.profileMgr.profiles.removeAll()
            if let serversArray = resJSON["data"] as? [[String:Any]] {
                for serverDict in serversArray {
                    let profile = ServerProfile.fromDictionaryAPI(serverDict as [String : AnyObject])
                    
                    let (dupResult, _) = self.profileMgr.isDuplicated(profile: profile)
                    let (existResult, existIndex) = self.profileMgr.isExisted(profile: profile)
                    if dupResult {
                        continue
                    }
                    if existResult {
                        self.profileMgr.profiles.replaceSubrange(Range(existIndex..<existIndex + 1), with: [profile])
                        continue
                    }
                    self.profileMgr.profiles.append(profile)
                    
                }
            } else {
                self.pushNotification(title: "更新失败", subtitle: "", info: "账户信息已过期，更新失败")
            }
            self.profileMgr.save()
            
            (NSApplication.shared().delegate as! AppDelegate).updateServersMenu()
            (NSApplication.shared().delegate as! AppDelegate).updateRunningModeMenu()
            
            self.pushNotification(title: "更新成功", subtitle: "", info: "节点更新成功")
            
        }
        
        sendRequest(url: "\(baseURL)/api/token",
                    parameters: ["email":email,"passwd":pwd],
                    options: HTTPMethod.post, callback: {resJson in
                        
                        if let ret = resJson["ret"] as? Int,
                            let data = resJson["data"] as? NSDictionary{
                            if ret == 1{
                                UserProfile.instance.userToken = data["token"] as? String
                                UserProfile.instance.userID = data["user_id"] as? Int
                                UserProfile.instance.save()
                                
                                self.sendRequest(url: "\(self.baseURL)/api/node?access_token=\(UserProfile.instance.userToken!)", parameters: [:], options: HTTPMethod.get, callback: {resJson in
                                    
                                    updateServerHandler(resJSON: resJson)
                                })
                            }
                        }
        })
    }
    
    
    public func save() {
        let defaults = UserDefaults.standard
        
        defaults.set(email, forKey: "UserMail")
        defaults.set(pwd, forKey: "UserPwd")
        defaults.set(userToken, forKey: "userToken")
        defaults.set(userID, forKey: "userID")
    }
    
    
    fileprivate func pushNotification(title: String, subtitle: String, info: String){
        let userNote = NSUserNotification()
        userNote.title = title
        userNote.subtitle = subtitle
        userNote.informativeText = info
        userNote.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default
            .deliver(userNote);
    }
}


protocol UserProfileDelegate {
    func didStartRequest()
    func didFinishRequest()
    func didLogIn()
    func foundWrongLogInfo()
}




