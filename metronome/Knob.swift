//
//  Knob.swift
//  metronome
//
//  Created by Erika Ji on 12/5/17.
//  Copyright © 2017 Erika Ji. All rights reserved.
//
//  This Knob class extends the Knob class specified in a tutorial by Sam Davies and Mikael Konutgan
//  (https://www.raywenderlich.com/82058/custom-control-tutorial-ios-swift-reusable-knob).
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

public class Knob: UIControl {
    // MARK: Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        createSublayers()
        let gr = RotationGestureRecognizer(target: self, action: #selector(self.handleRotation))
        self.addGestureRecognizer(gr)
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    
    // MARK: Private Constants and Variables
    private let knobRenderer = KnobRenderer()
    private var backingValue: Float = 0.0
    
    
    
    // MARK: Public Variables
    /** Contains the receiver’s current value. */
    public var value: Float {
        get { return backingValue }
        set { setValue(value: newValue, animated: false) }
    }
    
    /** Specifies the angle of the start of the knob control track. Defaults to -11π/8 */
    public var startAngle: CGFloat {
        get { return knobRenderer.startAngle }
        set { knobRenderer.startAngle = newValue }
    }
    
    /** Specifies the end angle of the knob control track. Defaults to 3π/8 */
    public var endAngle: CGFloat {
        get { return knobRenderer.endAngle }
        set { knobRenderer.endAngle = newValue }
    }
    
    /** Specifies the width in points of the knob control track. Defaults to 2.0 */
    public var lineWidth: CGFloat {
        get { return knobRenderer.lineWidth }
        set { knobRenderer.lineWidth = newValue }
    }
    
    /** Specifies whether the pointer is linear or circular. */
    public var circularPointer: Bool {
        get {return knobRenderer.circularPointer }
        set {knobRenderer.circularPointer = newValue }
    }
    
    /** Specifies the width in points of the linear pointer on the knob. Defaults to 2.0. Does not affect the circular pointer. */
    public var pointerWidth: CGFloat {
        get { return knobRenderer.pointerWidth }
        set { knobRenderer.pointerWidth = newValue }
    }
    
    /** Specifies the length in points of the linear pointer on the knob. Defaults to 6.0. Does not affect the circular pointer. */
    public var pointerLength: CGFloat {
        get { return knobRenderer.pointerLength }
        set { knobRenderer.pointerLength = newValue }
    }
    
    /** Specifies the radius in points of the circular pointer on the knob. Defaults to 3.0. Does not affect the linear pointer. */
    public var pointerRadius: CGFloat {
        get { return knobRenderer.pointerRadius }
        set { knobRenderer.pointerRadius = newValue }
    }
    
    /** Contains the minimum value of the receiver. */
    public var minimumValue: Float = 0.0
    
    /** Contains the maximum value of the receiver. */
    public var maximumValue: Float = 1.0
    
    /** Contains a Boolean value indicating whether changes
     in the sliders value generate continuous update events. */
    public var continuous = true
    
    
    
    // MARK: Functions
    public override func tintColorDidChange() {
        knobRenderer.strokeColor = tintColor
    }
    
    /** Sets the receiver’s current value, allowing you to animate the change visually. */
    public func setValue(value: Float, animated: Bool) {
        if value != self.value {
            // Save the value to the backing value
            // Make sure we limit it to the requested bounds
            self.backingValue = min(self.maximumValue, max(self.minimumValue, value))
            
            // Now let's update the knob with the correct angle
            let angleRange = endAngle - startAngle
            let valueRange = CGFloat(maximumValue - minimumValue)
            let angle = CGFloat(value - minimumValue) / valueRange * angleRange + startAngle
            knobRenderer.setPointerAngle(pointerAngle: angle, animated: animated)
        }
    }
    
    private func createSublayers() {
        knobRenderer.update(bounds: bounds)
        
        // Setup track
        knobRenderer.strokeColor = tintColor
        knobRenderer.startAngle = -CGFloat(CGFloat.pi * 11.0 / 8.0)
        knobRenderer.endAngle = CGFloat(CGFloat.pi * 3.0 / 8.0)
        knobRenderer.lineWidth = 2.0

        // Setup pointer
        knobRenderer.circularPointer = false
        knobRenderer.pointerWidth = 2.0
        knobRenderer.pointerLength = 6.0
        knobRenderer.pointerRadius = 3.0 // initialized just in case
        knobRenderer.pointerAngle = knobRenderer.startAngle
        
        layer.addSublayer(knobRenderer.trackLayer)
        layer.addSublayer(knobRenderer.trackEndsLayer)
        layer.addSublayer(knobRenderer.pointerLayer)
    }
    
    @objc private func handleRotation(sender: AnyObject) {
        let gr = sender as! RotationGestureRecognizer
        
        // 1. Mid-point angle
        let midPointAngle = (2.0 * CGFloat.pi + self.startAngle - self.endAngle) / 2.0 + self.endAngle
        
        // 2. Ensure the angle is within a suitable range
        var boundedAngle = gr.rotation
        if boundedAngle > midPointAngle {
            boundedAngle -= 2.0 * CGFloat.pi
        } else if boundedAngle < (midPointAngle - 2.0 * CGFloat.pi) {
            boundedAngle += 2 * CGFloat.pi
        }
        
        // 3. Bound the angle to within the suitable range
        boundedAngle = min(self.endAngle, max(self.startAngle, boundedAngle))
        
        // 4. Convert the angle to a value
        let angleRange = endAngle - startAngle
        let valueRange = maximumValue - minimumValue
        let valueForAngle = Float(boundedAngle - startAngle) / Float(angleRange) * valueRange + minimumValue
        
        // 5. Set the control to this value
        self.value = valueForAngle
        
        if continuous {
            sendActions(for: .valueChanged)
        } else {
            // Only send an update if the gesture has completed
            if (gr.state == UIGestureRecognizerState.ended) || (gr.state == UIGestureRecognizerState.cancelled) {
                sendActions(for: .valueChanged)
            }
        }
    }
}



private class KnobRenderer {
    // MARK: Initialization
    init() {
        trackLayer.fillColor = UIColor.clear.cgColor // track has no interior
        pointerLayer.fillColor = UIColor.white.cgColor // circle pointer's interior color
    }
    
    
    
    // MARK: Variables
    var strokeColor: UIColor {
        get {
            return UIColor(cgColor: trackLayer.strokeColor!)
        }
        set(strokeColor) {
            trackLayer.strokeColor = strokeColor.cgColor
            trackEndsLayer.fillColor = strokeColor.cgColor
        }
    }
    var startAngle: CGFloat = 0.0 {
        didSet { update() }
    }
    var endAngle: CGFloat = 0.0 {
        didSet { update() }
    }
    var lineWidth: CGFloat = 1.0 {
        didSet { update() }
    }
    
    var circularPointer: Bool = false {
        didSet { update() }
    }
    var pointerWidth: CGFloat = 1.0 {
        didSet { update() }
    }
    var pointerLength: CGFloat = 0.0 {
        didSet { update() }
    }
    var pointerRadius: CGFloat = 0.0 {
        didSet { update() }
    }
    var backingPointerAngle: CGFloat = 0.0
    var pointerAngle: CGFloat {
        get { return backingPointerAngle }
        set { setPointerAngle(pointerAngle: newValue, animated: false) }
    }
    
    let trackLayer = CAShapeLayer()
    let trackEndsLayer = CAShapeLayer()
    let pointerLayer = CAShapeLayer()
    
    
    
    // MARK: Functions
    func setPointerAngle(pointerAngle: CGFloat, animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointerLayer.transform = CATransform3DMakeRotation(pointerAngle, 0.0, 0.0, 0.1)
        if animated {
            let midAngle = (max(pointerAngle, self.pointerAngle) - min(pointerAngle, self.pointerAngle) ) / 2.0 + min(pointerAngle, self.pointerAngle)
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            animation.duration = 0.25
            
            animation.values = [self.pointerAngle, midAngle, pointerAngle]
            animation.keyTimes = [0.0, 0.5, 1.0]
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            pointerLayer.add(animation, forKey: nil)
        }
        CATransaction.commit()
        self.backingPointerAngle = pointerAngle
    }
    
    func updateTrackLayerPath() {
        let arcCenter = CGPoint(x: trackLayer.bounds.width / 2.0, y: trackLayer.bounds.height / 2.0)
        let offset = max(pointerLength, trackLayer.lineWidth / 2.0)
        let radius = min(trackLayer.bounds.height, trackLayer.bounds.width) / 2.0 - offset;
        let path = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        trackLayer.path = path.cgPath

        // Create rounded track ends for round pointer
        if circularPointer {
            // Set coordinates
            let startX = trackLayer.bounds.width / 2.0 - (radius * sin(3 * CGFloat.pi / 2 - startAngle)) - trackLayer.lineWidth / 2.0
            let startY = trackLayer.bounds.height / 2.0 - (radius * cos(3 * CGFloat.pi / 2 - startAngle)) - trackLayer.lineWidth / 2.0
            let endX = trackLayer.bounds.width / 2.0 + (radius * sin(CGFloat.pi / 2 - endAngle)) - trackLayer.lineWidth / 2.0
            let endY = trackLayer.bounds.height / 2.0 + (radius * cos(CGFloat.pi / 2 - endAngle)) - trackLayer.lineWidth / 2.0
            
            // Draw shapes
            let startRect = CGRect(x: startX, y: startY, width: trackLayer.lineWidth, height: trackLayer.lineWidth)
            let startPath = UIBezierPath(ovalIn:startRect)
            let endRect = CGRect(x: endX, y: endY, width: trackLayer.lineWidth, height: trackLayer.lineWidth)
            let endPath = UIBezierPath(ovalIn:endRect)
            startPath.append(endPath)
            trackEndsLayer.path = startPath.cgPath
        }
    }
    
    func updatePointerLayerPath() {
        let path = UIBezierPath()
        if !circularPointer {
            path.move(to: CGPoint(x: pointerLayer.bounds.width - trackLayer.lineWidth / 2.0 + pointerLength / 2.0, y: pointerLayer.bounds.height / 2.0))
            path.addLine(to: CGPoint(x: pointerLayer.bounds.width - trackLayer.lineWidth / 2.0 - pointerLength / 2.0, y: pointerLayer.bounds.height / 2.0))
        } else {
            let circleRect = CGRect(x: pointerLayer.bounds.width - trackLayer.lineWidth / 2.0 - pointerRadius, y: pointerLayer.bounds.height / 2.0 - pointerRadius, width: pointerRadius * 2.0, height: pointerRadius * 2.0)
            let circlePath = UIBezierPath(ovalIn: circleRect)
            path.append(circlePath)
        }
        pointerLayer.path = path.cgPath
    }
    
    func update() {
        trackLayer.lineWidth = lineWidth
        pointerLayer.lineWidth = pointerWidth
        
        updateTrackLayerPath()
        updatePointerLayerPath()
    }
    
    func update(bounds: CGRect) {
        let position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        
        trackLayer.bounds = bounds
        trackLayer.position = position
        
        pointerLayer.bounds = bounds
        pointerLayer.position = position
        
        update()
    }
}



private class RotationGestureRecognizer: UIPanGestureRecognizer {
    // MARK: Initialization
    init(target: AnyObject, action: Selector) {
        super.init(target: target, action: action)
        
        minimumNumberOfTouches = 1
        maximumNumberOfTouches = 1
    }
    
    
    
    // MARK: Variables
    var rotation: CGFloat = 0.0
    
    
    
    // MARK: Functions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches as Set<UITouch>, with: event)
        updateRotationWithTouches(touches: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches as Set<UITouch>, with: event)
        updateRotationWithTouches(touches: touches)
    }
    
    func updateRotationWithTouches(touches: Set<NSObject>) {
        if let touch = touches[touches.startIndex] as? UITouch {
            self.rotation = rotationForLocation(location: touch.location(in: self.view))
        }
    }
    
    func rotationForLocation(location: CGPoint) -> CGFloat {
        let offset = CGPoint(x: location.x - view!.bounds.midX, y: location.y - view!.bounds.midY)
        return atan2(offset.y, offset.x)
    }
}
