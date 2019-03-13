//
//  Graphics.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IGraphics: class {
    var engineName: String { get }
    func link(to view: UIView)
    func unlink(from view: UIView)
    func pushOffset(_ offset: CGPoint)
    func popOffset()
    func render(drawingBlock: (IGraphics) -> Void)
    func stroke(points: [CGPoint], color: UIColor, width: CGFloat)
    func fill(frame: CGRect, color: UIColor)
    func drawLine(points: [CGPoint], color: UIColor, width: CGFloat)
}

func obtainGraphicsForCurrentDevice() -> IGraphics {
    if let context = EAGLContext(api: .openGLES1) {
        return OpenGraphics(context: context)
    }
    else {
        abort()
    }
}
