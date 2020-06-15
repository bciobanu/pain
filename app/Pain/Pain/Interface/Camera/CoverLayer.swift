//
//  CoverLayer.swift
//  Pain
//
//  Created by Andrei Popa on 12/06/2020.
//  Copyright © 2020 Andrei Popa. All rights reserved.
//

import UIKit

class CoverLayer: CAShapeLayer {
    
    func setShape(bounds: CGRect, weights: Weights) {
        self.path = UIBezierPath(rect: bounds).cgPath
        let maskPath = CGMutablePath()
        maskPath.addRect(CGRect(x: bounds.width * weights.left,
                                y: bounds.height * weights.top,
                                width: bounds.width * (1 - weights.left - weights.right),
                                height: bounds.height * (1 - weights.top - weights.bottom)))
        maskPath.addRect(bounds)
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath
        maskLayer.fillRule = .evenOdd
        self.mask = maskLayer
    }
}

struct Weights {
    var top: CGFloat
    var bottom: CGFloat
    var left: CGFloat
    var right: CGFloat
}
