//
//  File.swift
//  
//
//  Created by Neil Jain on 6/27/21.
//

import UIKit

open class PopPresentationController: UIPresentationController {
    
    private var keyboardWillAppearToken: Any?
    private var keyboardDidDisappearToken: Any?
    private var keyboardHeight: CGFloat = 0 {
        didSet {
            preferredContentSizeDidChange(forChildContentContainer: self.presentedViewController)
        }
    }
    public var targetHeight: CGFloat?
    
    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.setupKeyboardObserver()
    }
    
    open override var presentationStyle: UIModalPresentationStyle {
        .overCurrentContext
    }
    
    private lazy var chromeView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var shadowView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        view.layer.shadowOpacity = 0
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = .zero
        view.layer.masksToBounds = false
        view.layer.cornerRadius = 12
        view.alpha = 0
        return view
    }()
    
    private func setupChromeView() {
        guard let containerView = self.containerView else { return }
        containerView.addSubview(chromeView)
        containerView.addSubview(shadowView)
        
        chromeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        chromeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        chromeView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        chromeView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }
    
    private func setupKeyboardObserver() {
        self.keyboardWillAppearToken = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main, using: { [weak self] (notification) in
            self?.keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
        })
        
        self.keyboardDidDisappearToken = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main, using: { [weak self] (notification) in
            self?.keyboardHeight = 0
        })
    }
    
    open override func presentationTransitionWillBegin() {
        setupChromeView()
        guard let coordinator = presentedViewController.transitionCoordinator else {
            chromeView.alpha = 1
            shadowView.alpha = 1
            shadowView.layer.shadowOpacity = 0
            return
        }
        
        coordinator.animate { (context) in
            self.chromeView.alpha = 1
            self.shadowView.alpha = 1
            self.shadowView.layer.shadowOpacity = 1
        }
    }
    
    open override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            self.chromeView.alpha = 0
            self.shadowView.alpha = 0
            self.shadowView.layer.shadowOpacity = 0
            return
        }
        coordinator.animate { (context) in
            self.chromeView.alpha = 0
            self.shadowView.alpha = 0
            self.shadowView.layer.shadowOpacity = 0
        }
    }
    
    deinit {
        if let willAppearToken = self.keyboardWillAppearToken {
            NotificationCenter.default.removeObserver(willAppearToken)
        }
        if let didDisappearToken = self.keyboardDidDisappearToken {
            NotificationCenter.default.removeObserver(didDisappearToken)
        }
    }
    
    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        self.presentedView?.frame = frameOfPresentedViewInContainerView
        self.shadowView.frame = frameOfPresentedViewInContainerView
    }
    
    open override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = self.containerView, let presentedView = self.presentedView else { return .zero }
        
        let targetSize = CGSize(
            width: containerView.frame.width - 32,
            height: UIView.layoutFittingCompressedSize.height
        )
        
        var size = presentedView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
        
        if size.height >= (containerView.frame.height - keyboardHeight) {
            size.height = containerView.frame.height - 0 - keyboardHeight
        }
        if let height = targetHeight {
            size.width = targetSize.width
            size.height = height
        }
        
        let yPosition = (containerView.frame.height - size.height - keyboardHeight) / 2
        let xPosotion = (containerView.frame.width/2) - (size.width/2)
        return CGRect(x: xPosotion, y: yPosition, width: size.width, height: size.height)
    }
    
    private func finalFrame(forProposed origin: CGPoint, with size: CGSize) -> CGRect {
        var newOrigin = origin
        var newSize = size
        
        let maxX = (self.containerView?.bounds.width ?? 0) - (self.containerView?.safeAreaInsets.right ?? 0)
        let xValue = origin.x + size.width
        if maxX < xValue {
            let newX = maxX - 20 - size.width
            newOrigin.x = newX
        }
        
        let maxY = self.containerView?.bounds.height ?? 0
        let yValue = origin.y + size.height
        if maxY < yValue {
            let newHeight = maxY - origin.y - 16
            newSize.height = newHeight
        }
        return CGRect(origin: newOrigin, size: newSize)
    }

    open override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        self.presentedView?.frame = frameOfPresentedViewInContainerView
        self.shadowView.frame = frameOfPresentedViewInContainerView
    }
    
}
