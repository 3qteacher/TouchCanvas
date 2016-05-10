//
//  DataChannel.swift
//  TouchCanvas
//
//  Created by mtk80357 on 16/5/10.
//  Copyright © 2016年 Apple, Inc. All rights reserved.
//

import Foundation
class DataChannel: NSObject, TLKSocketIOSignalingDelegate{
    let signaling = TLKSocketIOSignaling.init(video: false)
    var webRTCEnable = false
    static let sharedInstance = DataChannel()
    private override init(){
        super.init()
        self.setupWebRTC()
    }
    
    func setupWebRTC(){
        self.signaling.delegate = self
        self.signaling.connectToServer("123.56.252.219", port: 443, secure: false, success: {
            self.signaling.joinRoom("Room", success: {
                NSLog("Join Room")
                }, failure: {
                    NSLog("Join Room Failed")
            })
            NSLog("connect success")
        }) { (e) in
            NSLog("connect Failed")
        }
    }
    
    func sendData(message: Dictionary<String, String>){
        if !webRTCEnable{
            return
        }
        dispatch_async(dispatch_get_main_queue()){
            self.signaling.sendDirMessage(message, successHandler: {
                //NSLog("Send Data Success.")
            }) { (error) in
                NSLog("Send Data Fail.")
            }
        }
    }
    
    //mark - TLKSocketIOSignalingDelegate
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, onDirMessage message: String!) {
        //NSLog("Receiving MSG [%@]", message)
        
    }
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, onDirOpen channel: RTCDataChannel!) {
        webRTCEnable = true
        /*
        self.signaling.sendDirMessage("Hello Baiping.", successHandler: {
            NSLog("Send Data Success.")
        }) { (error) in
            NSLog("Send Data Fail.")
        }*/
    }}