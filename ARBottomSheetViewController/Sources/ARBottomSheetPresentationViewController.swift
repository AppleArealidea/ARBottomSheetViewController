//
//  ARBottomSheetViewController.swift
//
//
//  Created by Семён C. Осипов on 14.02.2024.
//

import UIKit
import SnapKit

protocol ARBottomSheetPresentationViewControllerDelegate: AnyObject {
    var preferedControllerHeight: CGFloat {get}
    var interactionScrollView: UIScrollView? {get}
}

class ARBottomSheetPresentationViewController: UIPresentationController {
    
    private weak var customDelegate: ARBottomSheetPresentationViewControllerDelegate?
    
    private var originalY: CGFloat = 0
    private var controllerHeight: CGFloat?
    
    private var panGestureRecognizer: ARInitialTouchPanGestureRecognizer?
    
    private lazy var dimmingView: UIView = {
        let view = UIView()
        let recognizer = UITapGestureRecognizer(target: self,
                                                action: #selector(handleTap(recognizer:)))
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
        return view
    }()
    
    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         height: CGFloat = UIScreen.main.bounds.height) {
        
        self.controllerHeight = height
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
        
    }
    
    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         delegate: ARBottomSheetPresentationViewControllerDelegate) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.customDelegate = delegate
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return super.frameOfPresentedViewInContainerView }
        let width = container.bounds.size.width
        let preferedHeight: CGFloat = customDelegate?.preferedControllerHeight ?? controllerHeight ?? maxHeight()
        let height = min(preferedHeight, maxHeight())
        
        return CGRect(x: 0, y: container.bounds.size.height - height, width: width, height: height)
    }
    
    private func maxHeight() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        var topPadding: CGFloat = 0
        if let window = UIApplication.shared.windows.first {
            topPadding = window.safeAreaInsets.top
        }
        return screenHeight - topPadding
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        
        containerView.insertSubview(dimmingView, at: 0)
        
        let viewPan = ARInitialTouchPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        viewPan.delegate = self
        containerView.addGestureRecognizer(viewPan)
        panGestureRecognizer = viewPan
        
        if let panGestureRecognizer = panGestureRecognizer {
            customDelegate?.interactionScrollView?.panGestureRecognizer.require(toFail: panGestureRecognizer)
        }
        
        dimmingView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
        
        dimmingView.backgroundColor = .black.withAlphaComponent(0)
        UIView.animate(withDuration: 0.25) {
            self.dimmingView.backgroundColor = .black.withAlphaComponent(0.5)
        }
    }
    
    override func dismissalTransitionWillBegin() {
        UIView.animate(withDuration: 0.25) {
            self.dimmingView.backgroundColor = .black.withAlphaComponent(0)
        }
    }
    
    // MARK: Gestures
    @objc private func viewPanned(_ sender: UIPanGestureRecognizer) {
        let translateY = sender.translation(in: presentedView).y
        let velocityY = sender.velocity(in: presentedView).y
        
        switch sender.state {
        case .began:
            originalY = presentedViewController.view.frame.origin.y
        case .changed:
            if translateY > 0 {
                presentedViewController.view.frame.origin.y = originalY + translateY
            } /*else {
               let diff = presentedViewController.view.frame.origin.y / presentingViewController.view.frame.size.height
               presentedView?.frame.origin.y = originalY + translateY * diff
               containerView?.layoutSubviews()
               }*/
        case .ended:
            let presentedViewHeight = presentedViewController.view.frame.height
            let newY = presentedViewController.view.frame.origin.y + velocityY * 0.2
            let isMoreHalfProgress = dimmingView.frame.height - presentedViewHeight * 0.5 < newY
            isMoreHalfProgress ? moveAndDismissPresentedView() : setBackToOriginalPosition()
        default:
            break
        }
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
    
    private func setBackToOriginalPosition() {
        presentedViewController.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.presentedViewController.view.frame.origin.y = self.originalY
            self.presentedViewController.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func moveAndDismissPresentedView() {
        presentedViewController.view.layoutIfNeeded()
        dismissalTransitionWillBegin()
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            self.presentedViewController.view.frame.origin.y = self.dimmingView.frame.height
            self.presentedViewController.view.layoutIfNeeded()
        }, completion: { _ in
            self.presentingViewController.dismiss(animated: true, completion: nil)
        })
    }
}

extension ARBottomSheetPresentationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? ARInitialTouchPanGestureRecognizer else { return true }
        let velocity = panGestureRecognizer.velocity(in: presentedView)
        guard abs(velocity.y) > abs(velocity.x) else {return false}
        
        if let childScrollView = customDelegate?.interactionScrollView,
           let view = presentedView,
           let point = panGestureRecognizer.initialTouchLocation {
            let pointInChildScrollView = view.convert(point, to: childScrollView).y - childScrollView.contentOffset.y
            guard pointInChildScrollView > 0, pointInChildScrollView < childScrollView.bounds.height else {
                return true
            }
            
            let closeDirection = panGestureRecognizer.translation(in: presentedView).y > 0
            let contentOffset = childScrollView.contentOffset.y
            
            if closeDirection {
                return contentOffset <= -childScrollView.contentInset.top
            } else {
                return false
                /* let offset = contentOffset + childScrollView.bounds.height - childScrollView.contentInset.bottom
                 let contentSize = childScrollView.contentSize.height.rounded(.toNearestOrAwayFromZero)
                 return offset >= contentSize */
            }
        }
        return true
    }
}
