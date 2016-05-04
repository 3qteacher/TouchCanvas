/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The primary view controller that hosts a `CanvasView` for the user to interact with.
*/

import UIKit

class ViewController: UIViewController, TLKSocketIOSignalingDelegate{
    // MARK: Properties
    
    var visualizeAzimuth = false
    
    let reticleView: ReticleView = {
        let view = ReticleView(frame: CGRect.null)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidden = true
        
        return view
    }()
    
    var canvasView: CanvasView {
        return view as! CanvasView
    }
    
    let signaling = TLKSocketIOSignaling.init(video: false)
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        canvasView.addSubview(reticleView)
        signaling.delegate = self
        /*
        signaling.connectToServer("signaling.simplewebrtc.com", port: 80, secure: false, success: {
            self.signaling.joinRoom("Room", success: {
                NSLog("Join Room")
                }, failure: {
                 NSLog("Join Room Failed")
            })
            NSLog("connect success")
            }, failure: {})
        
        })*/
        signaling.connectToServer("signaling.simplewebrtc.com", port: 80, secure: false, success: {
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
    
    // MARK: Touch Handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    reticleView.hidden = false
                    updateReticleViewWithTouch(touch, event: event)
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    updateReticleViewWithTouch(touch, event: event)
                    
                    // Use the last predicted touch to update the reticle.
                    guard let predictedTouch = event?.predictedTouchesForTouch(touch)?.last else { return }
                    
                    updateReticleViewWithTouch(predictedTouch, event: event, isPredicted: true)
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        canvasView.endTouches(touches, cancel: false)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    reticleView.hidden = true
                }
            }
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard let touches = touches else { return }
        canvasView.endTouches(touches, cancel: true)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    reticleView.hidden = true
                }
            }
        }
    }
    
    override func touchesEstimatedPropertiesUpdated(touches: Set<NSObject>) {
        canvasView.updateEstimatedPropertiesForTouches(touches)
    }
    //mark - TLKSocketIOSignalingDelegate
    /*
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, onDirMessage message: NSString!) {
        NSLog("Receiving MSG [%@]", message)
    }
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, onDirOpen channel: RTCDataChannel) {
        self.signaling.sendDirMessage
    }*/
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, onDirMessage message: String!) {
        NSLog("Receiving MSG [%@]", message)
    }
    func socketIOSignaling(socketIOSignaling: TLKSocketIOSignaling!, onDirOpen channel: RTCDataChannel!) {
        self.signaling.sendDirMessage("Hello Baiping.", successHandler: {
               NSLog("Send Data Success.")
            }) { (error) in
                NSLog("Send Data Fail.")
        }
    }
    // MARK: Actions
    
    @IBAction func clearView(sender: UIBarButtonItem) {
        canvasView.clear()
    }
    
    @IBAction func toggleDebugDrawing(sender: UIButton) {
        canvasView.isDebuggingEnabled = !canvasView.isDebuggingEnabled
        visualizeAzimuth = !visualizeAzimuth
        sender.selected = canvasView.isDebuggingEnabled
    }
    
    @IBAction func toggleUsePreciseLocations(sender: UIButton) {
        canvasView.usePreciseLocations = !canvasView.usePreciseLocations
        sender.selected = canvasView.usePreciseLocations
    }
    
    // MARK: Rotation
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.LandscapeLeft, .LandscapeRight]
    }
    
    // MARK: Convenience
    
    func updateReticleViewWithTouch(touch: UITouch?, event: UIEvent?, isPredicted: Bool = false) {
        guard let touch = touch where touch.type == .Stylus else { return }
        
        reticleView.predictedDotLayer.hidden = !isPredicted
        reticleView.predictedLineLayer.hidden = !isPredicted
        
        let azimuthAngle = touch.azimuthAngleInView(view)
        let azimuthUnitVector = touch.azimuthUnitVectorInView(view)
        let altitudeAngle = touch.altitudeAngle
        
        if isPredicted {
            reticleView.predictedAzimuthAngle = azimuthAngle
            reticleView.predictedAzimuthUnitVector = azimuthUnitVector
            reticleView.predictedAltitudeAngle = altitudeAngle
        }
        else {
            let location = touch.preciseLocationInView(view)
            reticleView.center = location
            reticleView.actualAzimuthAngle = azimuthAngle
            reticleView.actualAzimuthUnitVector = azimuthUnitVector
            reticleView.actualAltitudeAngle = altitudeAngle
        }
    }
}
