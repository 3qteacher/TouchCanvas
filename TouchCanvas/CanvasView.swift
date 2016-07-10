/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `CanvasView` tracks `UITouch`es and represents them as a series of `Line`s.
*/

import UIKit

class CanvasView: UIView {
    // MARK: Properties
    
    let isPredictionEnabled = UIDevice.currentDevice().userInterfaceIdiom == .Pad
    let isTouchUpdatingEnabled = true
    var usePreciseLocations = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    var isDebuggingEnabled = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    var needsFullRedraw = false
    //Test
    var count = 0
    /// Array containing all line objects that need to be drawn in `drawRect(_:)`.
    var lines = [Line]()

    /// Array containing all line objects that have been completely drawn into the frozenContext.
    var finishedLines = [Line]()
    
    override class func layerClass() -> AnyClass {
        return CATiledLayer.self
    }
    
    /*
    override init?(frame: CGRect) {
        super.init(frame: frame)
        guard let layer = self.layer as? CATiledLayer else {  }
        layer.contentsScale = UIScreen.mainScreen().scale
        layer.tileSize = self.bounds.size//CGSize(width: self.bounds., height: sideLength)
    }
    required init?(coder aDecoder: NSCoder) {
        //srand48(Int(NSDate().timeIntervalSince1970))
        super.init(coder: aDecoder)
        guard let layer = self.layer as? CATiledLayer else { return nil }
        layer.contentsScale = UIScreen.mainScreen().scale
        layer.tileSize = self.bounds.size//CGSize(width: self.bounds., height: sideLength)
    }*/
    /**
        Holds a map of `UITouch` objects to `Line` objects whose touch has not ended yet.
    
        Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
        in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
        be accessed in `NSResponder` callbacks and methods called from them.
    */
    let activeLines = NSMapTable.strongToStrongObjectsMapTable()
    
    /**
        Holds a map of `UITouch` objects to `Line` objects whose touch has ended but still has points awaiting
        updates.
        
        Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
        in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
        be accessed in `NSResponder` callbacks and methods called from them.
    */
    let pendingLines = NSMapTable.strongToStrongObjectsMapTable()

    /// A `CGContext` for drawing the last representation of lines no longer receiving updates into.
    lazy var frozenContext: CGContext = {
        let scale = CGFloat(2)
        var size = self.bounds.size
        NSLog("Width %f, Height %f", size.width , size.height)
        size.width *= scale
        size.height *= scale
        size.width = size.width/CANVAS_SIZE
        
        size.height = size.height/CANVAS_SIZE
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), 8, 0, colorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue)
        //let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), 8, 0, colorSpace, CGImageAlphaInfo.kCGImageAlphaPremultipliedLast)
        //CGContextBeginTransparencyLayer(context, nil)
        //CGContextSetRGBFillColor(context, 56, 67, 35, 1)
        CGContextSetLineCap(context, .Round)
        let transform = CGAffineTransformMakeScale(scale, scale)
        CGContextConcatCTM(context, transform)
        //CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height))
        return context!
    }()
    
    /// An optional `CGImage` containing the last representation of lines no longer receiving updates.
    var frozenImage: CGImage?

    /*
    override init(frame: CGRect) {
        super.init(frame: frame)
        //let layer = self.layer as! CATiledLayer
        //ayer.tileSize = CGSizeMake(300, 300)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let layer = self.layer as! CATiledLayer
        layer.contentsScale = UIScreen.mainScreen().scale
        layer.tileSize =  self.bounds.size
    }*/
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //NSLog("Touch Began")
        if isMove{
            //CGContextClearRect(frozenContext, CGRectMake(0 , 0,bounds.size.width/CANVAS_SIZE, bounds.size.height/CANVAS_SIZE))
            //CGContextDrawImage(frozenContext, CGRectMake(0 , 0,bounds.size.width, bounds.size.height), UIGraphicsGetImageFromCurrentImageContext().CGImage!)
            isMove = false
        }
        drawTouches(touches, withEvent: event)
        
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        drawTouches(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        drawTouches(touches, withEvent: event)
        endTouches(touches, cancel: false)
        //NSLog("Test Count %d", count)
        //count = 0
        //NSLog("Touch End")
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        guard let touches = touches else { return }
        endTouches(touches, cancel: true)
    }
    
    // MARK: Drawing
    //var defoutPoint = CGPointMake(0, 0)
    var isMove = false
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!

        //NSLog("Draw Rect")
        CGContextSetLineCap(context, .Round)

        if (needsFullRedraw) {
            setFrozenImageNeedsUpdate()
            NSLog("Clear")
            //CGContextClearRect(frozenContext, CGRectMake(defoutPoint.x , defoutPoint.y,bounds.size.width/CANVAS_SIZE, bounds.size.height/CANVAS_SIZE))
            CGContextClearRect(frozenContext, bounds)
            for array in [finishedLines,lines] {
                for line in array {
                    line.drawCommitedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations)
                }
            }
            needsFullRedraw = false
        }
        //CGContextBeginTransparencyLayer(frozenContext, nil)


        frozenImage = frozenImage ?? CGBitmapContextCreateImage(frozenContext)
        //CGContextEndTransparencyLayer(frozenContext)
        //	UIGraphicsGetImage
        if let frozenImage = frozenImage {
            CGContextDrawImage(context, CGRectMake(defoutPoint.x , defoutPoint.y,bounds.size.width/CANVAS_SIZE, bounds.size.height/CANVAS_SIZE), frozenImage)
            //CGContextDrawImage(context, rect, frozenImage)
            //NSLog("Point %@", NSStringFromCGRect(bounds))
            //CGContextDrawImage(context, bounds, frozenImage)
        }
        //NSLog("Line Count %d", lines.count)
        for line in lines {
            //NSLog("Line Points %d", line.points.count)
            line.drawInContext(context, isDebuggingEnabled: true, usePreciseLocation: usePreciseLocations)
            
        }
    }
    
    func setFrozenImageNeedsUpdate() {
        frozenImage = nil
    }
    
    // MARK: Actions
    
    func clear() {
        activeLines.removeAllObjects()
        pendingLines.removeAllObjects()
        lines.removeAll()
        finishedLines.removeAll()
        needsFullRedraw = true
        setNeedsDisplay()
    }
    
    // MARK: Convenience
    
    func drawTouches(touches: Set<UITouch>, withEvent event: UIEvent?) {
        var updateRect = CGRect.null
        
        for touch in touches {
            // Retrieve a line from `activeLines`. If no line exists, create one.
            let line = activeLines.objectForKey(touch) as? Line ?? addActiveLineForTouch(touch)
            
            /*
                Remove prior predicted points and update the `updateRect` based on the removals. The touches 
                used to create these points are predictions provided to offer additional data. They are stale 
                by the time of the next event for this touch.
            */
            updateRect.unionInPlace(line.removePointsWithType(.Predicted))
            
            /*
                Incorporate coalesced touch data. The data in the last touch in the returned array will match
                the data of the touch supplied to `coalescedTouchesForTouch(_:)`
            */
            let coalescedTouches = event?.coalescedTouchesForTouch(touch) ?? []
            let coalescedRect = addPointsOfType(.Coalesced, forTouches: coalescedTouches, toLine: line, currentUpdateRect: updateRect)
            updateRect.unionInPlace(coalescedRect)
            
            /*
                Incorporate predicted touch data. This sample draws predicted touches differently; however, 
                you may want to use them as inputs to smoothing algorithms rather than directly drawing them. 
                Points derived from predicted touches should be removed from the line at the next event for 
                this touch.
            */
            if isPredictionEnabled {
                let predictedTouches = event?.predictedTouchesForTouch(touch) ?? []
                let predictedRect = addPointsOfType(.Predicted, forTouches: predictedTouches, toLine: line, currentUpdateRect: updateRect)
                updateRect.unionInPlace(predictedRect)
            }
        }


        setNeedsDisplayInRect(updateRect)
    }
    
    func addActiveLineForTouch(touch: UITouch) -> Line {
        let newLine = Line()
        
        activeLines.setObject(newLine, forKey: touch)
        
        lines.append(newLine)
        
        return newLine
    }
    
    func addPointsOfType( var type: LinePoint.PointType, forTouches touches: [UITouch], toLine line: Line, currentUpdateRect updateRect: CGRect) -> CGRect {
        var accumulatedRect = CGRect.null
        
        for (idx, touch) in touches.enumerate() {
            let isStylus = touch.type == .Stylus
            
            // The visualization displays non-`.Stylus` touches differently.
            if !isStylus {
                type.unionInPlace(.Finger)
               
            }
            
            // Touches with estimated properties require updates; add this information to the `PointType`.
            /*
            if isTouchUpdatingEnabled && !touch.estimatedProperties.isEmpty {
                type.unionInPlace(.NeedsUpdate)
               
            }
            */
            // The last touch in a set of `.Coalesced` touches is the originating touch. Track it differently.
            if type.contains(.Coalesced) && idx == touches.count - 1 {
                type.subtractInPlace(.Coalesced)
                type.unionInPlace(.Standard)
                
            }
            
            let touchRect = line.addPointOfType(type, forTouch: touch)
            accumulatedRect.unionInPlace(touchRect)
            count += 1
            commitLine(line)
        }
        
        return updateRect.union(accumulatedRect)
    }
    
    func endTouches(touches: Set<UITouch>, cancel: Bool) {
        var updateRect = CGRect.null
        
        for touch in touches {
            // Skip over touches that do not correspond to an active line.
            guard let line = activeLines.objectForKey(touch) as? Line else { continue }
            
            // If this is a touch cancellation, cancel the associated line.
            if cancel { updateRect.unionInPlace(line.cancel()) }
            
            // If the line is complete (no points needing updates) or updating isn't enabled, move the line to the `frozenImage`.
            /*
            if line.isComplete || !isTouchUpdatingEnabled {
                finishLine(line)
            }
            // Otherwise, add the line to our map of touches to lines pending update.
            else {
                pendingLines.setObject(line, forKey: touch)
            }*/
 
            finishLine(line)
            
            // This touch is ending, remove the line corresponding to it from `activeLines`.
            activeLines.removeObjectForKey(touch)
        }
        dispatch_async(DataChannel.myQueue, { () -> Void in
            
            DataChannel.sharedInstance.sendData(["action": "end"])
        })
        setNeedsDisplayInRect(updateRect)
        //CGContextClearRect(frozenContext, CGRectMake(0,0,bounds.size.width/CANVAS_SIZE, bounds.size.height/CANVAS_SIZE))
    }
    
    func updateEstimatedPropertiesForTouches(touches: Set<NSObject>) {
        guard isTouchUpdatingEnabled, let touches = touches as? Set<UITouch> else { return }
        //NSLog("Receiving Update Event")
        for touch in touches {
            var isPending = false
            
            // Look to retrieve a line from `activeLines`. If no line exists, look it up in `pendingLines`.
            let possibleLine: Line? = activeLines.objectForKey(touch) as? Line ?? {
                let pendingLine = pendingLines.objectForKey(touch) as? Line
                isPending = pendingLine != nil
                return pendingLine
            }()
            
            // If no line is related to the touch, return as there is no additional work to do.
            guard let line = possibleLine else { return }
            
            switch line.updateWithTouch(touch) {
                case (true, let updateRect):
                    setNeedsDisplayInRect(updateRect)
                default:
                    ()
            }
            
            // If this update updated the last point requiring an update, move the line to the `frozenImage`.
            if isPending && line.isComplete {
                finishLine(line)
                pendingLines.removeObjectForKey(touch)
            }
            // Otherwise, have the line add any points no longer requiring updates to the `frozenImage`.
            else {
                commitLine(line)
            }
            
        }
    }
    
    func commitLine(line: Line) {
        // Have the line draw any segments between points no longer being updated into the `frozenContext` and remove them from the line.
        line.drawFixedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations)
        setFrozenImageNeedsUpdate()
    }
    
    func finishLine(line: Line) {
        // Have the line draw any remaining segments into the `frozenContext`. All should be fixed now.
        line.drawFixedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations, commitAll: true)
        setFrozenImageNeedsUpdate()
        
        // Cease tracking this line now that it is finished.
        lines.removeAtIndex(lines.indexOf(line)!)

        // Store into finished lines to allow for a full redraw on option changes.
        finishedLines.append(line)
    }
}
