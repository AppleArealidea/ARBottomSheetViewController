//
//  ARBottomSheetViewController.swift
//
//
//  Created by Семён C. Осипов on 14.02.2024.
//

import UIKit
import SnapKit

public protocol ARBottomSheetViewControllerDelegate: AnyObject {
    var contentHeight: CGFloat {get}
    var childScrollView: UIScrollView? {get}
}

public class ARBottomSheetViewController: UIViewController {
    
    public weak var sheetDelegate: ARBottomSheetViewControllerDelegate?
    
    // MARK: Views
    private let stickView: UIView = {
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .label
        } else {
            view.backgroundColor = .black
        }
        view.snp.makeConstraints {
            $0.width.equalTo(65)
            $0.height.equalTo(5)
        }
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    /**
     Add your content on this view
     */
    public var contentBackgroundView: UIView {
        contentView
    }
    
    /**
     Init View controller
     */
    public init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        modalPresentationStyle = .custom
        transitioningDelegate = self
        setupViews()
        
        view.clipsToBounds = true
        view.layer.cornerRadius = 30
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
    }
    
    private func setupViews() {
        view.addSubview(stickView)
        view.addSubview(contentView)
        
        stickView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().inset(20)
        }
        
        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(stickView.snp.bottom).offset(20)
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension ARBottomSheetViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? {
        return ARBottomSheetPresentationViewController(presentedViewController: presented,
                                                       presenting: presenting,
                                                       delegate: self)
    }
}

// MARK: - LRVBottomSheetPresentationViewControllerDelegate
extension ARBottomSheetViewController: ARBottomSheetPresentationViewControllerDelegate {
    var interactionScrollView: UIScrollView? {
        return sheetDelegate?.childScrollView
    }
    
    var preferedControllerHeight: CGFloat {
        let stickSize: CGFloat = 5 + 20 + 20
        var bottomPadding: CGFloat = 0
        if let window = UIApplication.shared.windows.first {
            bottomPadding = window.safeAreaInsets.bottom
        }
        return stickSize + (sheetDelegate?.contentHeight ?? 0) + bottomPadding
    }
}

