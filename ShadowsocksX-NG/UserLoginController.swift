//
//  UserLoginController.swift
//  ShadowsocksX-NG
//
//  Created by billphilip22 on 2019/1/22.
//  Copyright © 2019 qiuyuzhou. All rights reserved.
//

import Cocoa
import Alamofire

class UserLoginController: NSWindowController{
    
    var isLoginIn:Bool?
    
    
    @IBOutlet var userDomainTextField: NSTextField!
    
    @IBOutlet var userMailTextfield: NSTextField!
    
    @IBOutlet var userPwdField: NSSecureTextField!
    
    @IBOutlet var progressBar: NSProgressIndicator!
    
    @IBOutlet var loginButton: NSButton!
    
    @IBOutlet var errorIndicator: NSTextField!
    
    @IBAction func loginButton(_ sender: NSButton) {
        errorIndicator.isHidden = true
        UserDefaults.standard.set(userDomainTextField.stringValue, forKey: "baseURL")
        UserProfile.instance.login(email: userMailTextfield.stringValue, pwd: userPwdField.stringValue, url:userDomainTextField.stringValue)
        
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        errorIndicator.isHidden = true
        
        UserProfile.instance.delegate = self
        
        userDomainTextField.stringValue = UserProfile.instance.baseURL
        userMailTextfield.stringValue = UserProfile.instance.email
        userPwdField.stringValue = UserProfile.instance.pwd
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
}

extension UserLoginController:UserProfileDelegate {
    func didStartRequest() {
        progressBar.startAnimation(loginButton)
    }
    
    func didFinishRequest() {
        progressBar.stopAnimation(loginButton)
    }
    
    func didLogIn() {
        close()
    }
    
    func foundWrongLogInfo() {
        errorIndicator.isHidden = false
    }
    
}

