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
    func render(drawingBlock: (IGraphics) -> Void)
    func setBackground(color: UIColor)
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
