//
//  ARInitialTouchPanGestureRecognizer.swift
//
//
//  Created by Семён C. Осипов on 14.02.2024.
//

import UIKit.UIGestureRecognizerSubclass

class ARInitialTouchPanGestureRecognizer: UIPanGestureRecognizer {
    var initialTouchLocation: CGPoint?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialTouchLocation = touches.first?.location(in: view)
    }
}

