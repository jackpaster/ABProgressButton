//
//  ABProgreeButton.swift
//  DreamHome
//
//  Created by Alex Bakhtin on 8/5/15.
//  Copyright © 2015 bakhtin. All rights reserved.
//

import UIKit

/**
    ABProgressButton provides functionality for creating custom animation of UIButton during processing some task.
    Should be created in IB as custom class UIButton to prevent title of the button appearing.
*/
@IBDesignable @objc class ABProgressButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 5.0
    @IBInspectable var borderWidth: CGFloat = 3.0
    @IBInspectable lazy var borderColor: UIColor = {
        return self.tintColor
    }()
    @IBInspectable lazy var circleBorderColor: UIColor = {
        return self.tintColor
    }()
    @IBInspectable var circleBorderWidth: CGFloat = 3.0
    @IBInspectable var circleRadius: CGFloat = 20.0
    @IBInspectable var circleCutAngle: CGFloat = 45.0
    @IBInspectable var circleBackgroundColor: UIColor = UIColor.whiteColor()
    private lazy var shapeBackgroundColor: UIColor = {
        return self.backgroundColor ?? self.circleBackgroundColor
    }()

    enum State {
        case Default, Progressing
    }
    var progressState: State = .Default {
        didSet {
            if(progressState == .Default) { self.updateToDefaultStateAnimated(true)}
            if(progressState == .Progressing) { self.updateToProgressingState()}
            self.updateProgressLayer()
        }
    }
    var progress: CGFloat? {
        didSet {
            assert(self.progressState == .Progressing, "Progress state should be .Progressing while changing progress value")
            progress = progress == nil ? nil : min(progress!, CGFloat(1.0))
            self.updateProgressLayer()
        }
    }
    
    private let firstStepAnimationTime = 0.3
    private let secondStepAnimationTime = 0.15
    private let textAppearingAnimationTime = 0.2
    private let progressUpdateAnimationTime = 0.1

    private var shapeLayer = CAShapeLayer()
    private lazy var crossLayer: CAShapeLayer = {
        let crossLayer = CAShapeLayer()
        crossLayer.path = self.crossPath().CGPath
        crossLayer.strokeColor = self.circleBorderColor.CGColor
        return crossLayer
    }()
    private lazy var progressLayer: CAShapeLayer = {
        let progressLayer = CAShapeLayer()
        progressLayer.strokeColor = self.circleBorderColor.CGColor
        progressLayer.fillColor = UIColor.clearColor().CGColor
        return progressLayer
    }()
    
    override var highlighted: Bool {
        didSet {
            self.crossLayer.strokeColor = highlighted ? self.circleBackgroundColor.CGColor : self.circleBorderColor.CGColor
            self.progressLayer.strokeColor = highlighted ? self.circleBackgroundColor.CGColor : self.circleBorderColor.CGColor
            if (highlighted) {
                self.shapeLayer.fillColor = (progressState == State.Default) ? self.borderColor.CGColor : self.circleBorderColor.CGColor
            }
            else {
                self.shapeLayer.fillColor = (progressState == State.Default) ? self.shapeBackgroundColor.CGColor : self.circleBackgroundColor.CGColor
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.privateInit()
        self.registerForNotifications()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.privateInit()
        self.registerForNotifications()
    }
    override func prepareForInterfaceBuilder() {
        self.privateInit()
    }
    deinit {
        self.unregisterFromNotifications()
    }

    private func privateInit() {
        self.setTitleColor(self.tintColor, forState: UIControlState.Normal)
        self.setTitleColor(self.shapeBackgroundColor, forState: UIControlState.Highlighted)
        self.layer.insertSublayer(self.shapeLayer, atIndex: 0)
        self.layer.insertSublayer(self.crossLayer, atIndex: 1)
        self.layer.insertSublayer(self.progressLayer, atIndex: 2)
        self.updateToDefaultStateAnimated(false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shapeLayer.frame = self.layer.bounds
        self.crossLayer.frame = self.layer.bounds
        self.progressLayer.frame = self.layer.bounds
    }
    
    private func updateToDefaultStateAnimated(animated:Bool) {
        self.shapeLayer.strokeColor = self.borderColor.CGColor;
        self.shapeLayer.fillColor = self.shapeBackgroundColor.CGColor
        self.crossLayer.hidden = true
        self.animateDefaultStateAnimated(animated)
    }
    private func updateToProgressingState() {
        self.titleLabel?.alpha = 0.0
        self.shapeLayer.strokeColor = self.circleBorderColor.CGColor
        self.shapeLayer.fillColor = self.circleBackgroundColor.CGColor
        self.crossLayer.hidden = false
        self.animateProgressingState(self.shapeLayer)
    }
    private func updateProgressLayer() {
        self.progressLayer.hidden = (self.progressState != .Progressing || self.progress == nil)
        if (self.progressLayer.hidden == false) {
            let progressCircleRadius = self.circleRadius-self.circleBorderWidth
            let progressArcAngle = CGFloat(M_PI) * 2 * self.progress! - CGFloat(M_PI_2)
            let circlePath = UIBezierPath()
            let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            circlePath.addArcWithCenter(center, radius:progressCircleRadius, startAngle:CGFloat(-M_PI_2), endAngle:progressArcAngle, clockwise:true)
            circlePath.lineWidth = self.circleBorderWidth
            
            let updateProgressAnimation = CABasicAnimation();
            updateProgressAnimation.keyPath = "path"
            updateProgressAnimation.fromValue = self.progressLayer.path
            updateProgressAnimation.toValue = circlePath.CGPath
            updateProgressAnimation.duration = progressUpdateAnimationTime
            self.progressLayer.path = circlePath.CGPath
            self.progressLayer.addAnimation(updateProgressAnimation, forKey: "update progress animation")
        }
    }
    
    private func animateDefaultStateAnimated(animated: Bool) {
        if !animated {
            self.shapeLayer.path = self.defaultStatePath().CGPath
            self.titleLabel?.alpha = 1.0
        } else {
            self.shapeLayer.removeAnimationForKey("rotation animation")
            
            let firstStepAnimation = CABasicAnimation();
            firstStepAnimation.keyPath = "path"
            firstStepAnimation.fromValue = self.shapeLayer.path
            firstStepAnimation.toValue = self.animateToCircleReplacePath().CGPath
            firstStepAnimation.duration = secondStepAnimationTime
            self.shapeLayer.path = self.animateToCircleFakeRoundPath().CGPath
            self.shapeLayer.addAnimation(firstStepAnimation, forKey: "first step animation")
            
            let secondStepAnimation = CABasicAnimation();
            secondStepAnimation.keyPath = "path"
            secondStepAnimation.fromValue = self.shapeLayer.path!
            secondStepAnimation.toValue = self.defaultStatePath().CGPath
            secondStepAnimation.beginTime = CACurrentMediaTime() + secondStepAnimationTime
            secondStepAnimation.duration = firstStepAnimationTime
            self.shapeLayer.path = self.defaultStatePath().CGPath
            self.shapeLayer.addAnimation(secondStepAnimation, forKey: "second step animation")
            
            let delay = secondStepAnimationTime + firstStepAnimationTime
            UIView.animateWithDuration(textAppearingAnimationTime, delay:delay, options: UIViewAnimationOptions.BeginFromCurrentState,
                animations: { () -> Void in
                    self.titleLabel?.alpha = 1.0
                }) { (complete) -> Void in }
        }
    }
    private func animateProgressingState(layer: CAShapeLayer) {
        let firstStepAnimation = CABasicAnimation();
        firstStepAnimation.keyPath = "path"
        firstStepAnimation.fromValue = layer.path
        firstStepAnimation.toValue = self.animateToCircleFakeRoundPath().CGPath
        firstStepAnimation.duration = firstStepAnimationTime
        layer.path = self.animateToCircleReplacePath().CGPath
        layer.addAnimation(firstStepAnimation, forKey: "first step animation")
        
        let secondStepAnimation = CABasicAnimation();
        secondStepAnimation.keyPath = "path"
        secondStepAnimation.fromValue = layer.path
        secondStepAnimation.toValue = self.progressingStatePath().CGPath
        secondStepAnimation.beginTime = CACurrentMediaTime() + firstStepAnimationTime
        secondStepAnimation.duration = secondStepAnimationTime
        layer.path = self.progressingStatePath().CGPath
        layer.addAnimation(secondStepAnimation, forKey: "second step animation")
        
        let animation = CABasicAnimation();
        animation.keyPath = "transform.rotation";
        animation.fromValue = 0 * M_PI
        animation.toValue = 2 * M_PI
        animation.repeatCount = Float.infinity
        animation.duration = 1.5
        animation.beginTime = CACurrentMediaTime() + firstStepAnimationTime + secondStepAnimationTime
        layer.addAnimation(animation, forKey: "rotation animation")
        UIView.animateWithDuration(textAppearingAnimationTime, animations: { () -> Void in
            self.titleLabel?.alpha = 0.0
        })
    }
    
    private func defaultStatePath() ->  UIBezierPath {
        let bordersPath = UIBezierPath(roundedRect:self.bounds, cornerRadius:self.cornerRadius)
        bordersPath.lineWidth = self.borderWidth
        return bordersPath
    }
    private func progressingStatePath() ->  UIBezierPath {
        let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        let circlePath = UIBezierPath()
        let startAngle = self.circleCutAngle/180 * CGFloat(M_PI)
        let endAngle = 2 * CGFloat(M_PI)
        circlePath.addArcWithCenter(center, radius:self.circleRadius, startAngle:startAngle, endAngle:endAngle, clockwise:true)
        circlePath.lineWidth = self.circleBorderWidth
        return circlePath
    }
    private func animateToCircleFakeRoundPath() ->  UIBezierPath {
        let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        let rect = CGRectMake(center.x - self.circleRadius, center.y - self.circleRadius, self.circleRadius * 2, self.circleRadius * 2)
        let bordersPath = UIBezierPath(roundedRect: rect, cornerRadius: self.circleRadius)
        bordersPath.lineWidth = self.borderWidth
        return bordersPath
    }
    private func animateToCircleReplacePath() ->  UIBezierPath {
        let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        let circlePath = UIBezierPath()
        circlePath.addArcWithCenter(center, radius:self.circleRadius, startAngle:CGFloat(0.0), endAngle:CGFloat(M_PI * 2), clockwise:true)
        circlePath.lineWidth = self.circleBorderWidth
        return circlePath
    }
    private func crossPath() -> UIBezierPath {
        let crossPath = UIBezierPath()
        let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        let point1 = CGPointMake(center.x - self.circleRadius/2, center.y + self.circleRadius / 2)
        let point2 = CGPointMake(center.x + self.circleRadius/2, center.y + self.circleRadius / 2)
        let point3 = CGPointMake(center.x + self.circleRadius/2, center.y - self.circleRadius / 2)
        let point4 = CGPointMake(center.x - self.circleRadius/2, center.y - self.circleRadius / 2)
        crossPath.moveToPoint(point1)
        crossPath.addLineToPoint(point3)
        crossPath.moveToPoint(point2)
        crossPath.addLineToPoint(point4)
        crossPath.lineWidth = self.circleBorderWidth
        return crossPath
    }

    private func registerForNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"applicationDidEnterBackground:",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"applicationWillEnterForeground:",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    private func unregisterFromNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    private func applicationDidEnterBackground(notification: NSNotification) {
        self.pauseLayer(self.layer)
    }
    private func applicationWillEnterForeground(notification: NSNotification) {
        self.resumeLayer(self.layer)
    }
    private func pauseLayer(layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), fromLayer:nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    private func resumeLayer(layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}