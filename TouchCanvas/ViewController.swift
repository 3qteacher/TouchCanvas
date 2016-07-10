/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The primary view controller that hosts a `CanvasView` for the user to interact with.
*/

import UIKit
let CANVAS_SIZE = CGFloat(2)
var defoutPoint = CGPointMake(0, 0)
class ViewController: UIViewController, UIScrollViewDelegate{
    // MARK: Properties
    
    var visualizeAzimuth = false
    var scrollView: UIScrollView!
    
    let reticleView: ReticleView = {
        let view = ReticleView(frame: CGRect.null)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidden = true
        
        return view
    }()
    //var with =
    var canvasView: CanvasView!
    let sideLength = CGFloat(100.0)
    var tiledLayer: CATiledLayer {
        return canvasView.layer as! CATiledLayer
    }    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //canvasView.addSubview(reticleView)
        DataChannel.sharedInstance
        //canvasView.setupWebRTC()
        //var withCan = self.view.bounds.width*CANVAS_SIZE
        //var heightCan = self.view.bounds.height*CANVAS_SIZE
        canvasView = CanvasView(frame: CGRectMake(0, 0, view.bounds.width*CANVAS_SIZE, view.bounds.height*CANVAS_SIZE))
        tiledLayer.tileSize = CGSize(width: sideLength, height: sideLength)
        tiledLayer.contentsScale = UIScreen.mainScreen().scale
        
        //NSLog("Canvas View Height %f", view.bounds.height)
        //canvasView.l
        canvasView.backgroundColor = UIColor.clearColor()

        scrollView = UIScrollView(frame: view.bounds)
        scrollView.userInteractionEnabled = true
        scrollView.scrollEnabled = true
        //scrollView.contentSize = CGSizeMake(canvasView.bounds.width, canvasView.bounds.he)
        scrollView.contentSize = canvasView.bounds.size
        scrollView.canCancelContentTouches = true
        scrollView.delaysContentTouches = false
        scrollView.bounces = false
        //scrollView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        //scrollView.minimumZoomScale = 0.4
        //scrollView.maximumZoomScale = 5.0
        scrollView.delegate = self
        scrollView.contentOffset = CGPointMake(0, 0)
        //scrollView.
        scrollView.addSubview(canvasView)
        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(scrollView)
        canvasView.userInteractionEnabled = true
        
    }
    
    // MARK: Touch Handling
    /*
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
                    NSLog("Receiving Touch Move Visualize")
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
    */
    override func touchesEstimatedPropertiesUpdated(touches: Set<NSObject>) {
        //canvasView.updateEstimatedPropertiesForTouches(touches)
    }
    // MARK: Actions
    
    @IBAction func clearView(sender: UIBarButtonItem) {
        canvasView.clear()
        DataChannel.sharedInstance.sendData(["action": "delete"])
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
    
    // MARK: UIScrollDelete
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //NSLog("Do Scroll X(%s), Y(%s)", String(), String(scrollView.contentOffset.y))
        //DataChannel.sharedInstance.sendData(["action": "scroll","x": String(scrollView.contentOffset.x),"y": String(scrollView.contentOffset.y)])
        
    }
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        defoutPoint = scrollView.contentOffset
        CGContextClearRect(canvasView.frozenContext, CGRectMake(0 , 0,canvasView.bounds.size.width/CANVAS_SIZE, canvasView.bounds.size.height/CANVAS_SIZE))
          //CGContextDrawImage(canvasView.frozenContext, CGRectMake(0 , 0,canvasView.bounds.size.width, canvasView.bounds.size.height), CGBitmapContextCreateImage(UIGraphicsGetCurrentContext()))
        
        canvasView.isMove = true
    }

    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
       return canvasView
    }
}
