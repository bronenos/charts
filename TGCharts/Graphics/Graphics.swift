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
    func setDelegate(_ delegate: IGraphicsDelegate?)
    func link(to view: UIView)
    func unlink(from view: UIView)
    func pushOffset(_ offset: CGPoint)
    func popOffset()
    func render(drawingBlock: (IGraphics) -> Void)
    func clear(color: UIColor)
    func place(points: [CGPoint], color: UIColor, width: CGFloat)
    func stroke(points: [CGPoint], color: UIColor, width: CGFloat)
    func fill(frame: CGRect, color: UIColor)
    func requestNodeTexture(size: CGSize) -> GraphicsTextureRef?
    func flushNodeTexture(_ texture: GraphicsTextureRef)
    func drawNodeTexture(_ texture: GraphicsTextureRef)
    func storeLabelTexture(meta: GraphicsTextureMeta) -> GraphicsTextureRef?
    func drawLabelTexture(_ texture: GraphicsTextureRef, in frame: CGRect)
    func discardTexture(_ texture: GraphicsTextureRef)
}

protocol IGraphicsDelegate: class {
    func interactionDidStart(at point: CGPoint)
    func interactionDidMove(to point: CGPoint)
    func interactionDidEnd(at point: CGPoint)
}

func obtainGraphicsForCurrentDevice() -> IGraphics {
    if let context = EAGLContext(api: .openGLES1) {
        return OpenGraphics(context: context)
    }
    else {
        abort()
    }
}

func calculateCoveringDuoPower(value: Int) -> Int {
    for i in (0 ..< 32).indices.reversed() {
        let bit = ((value & (1 << i)) > 0)
        guard bit else { continue }
        
        if value.nonzeroBitCount > 1 {
            return (1 << (i + 1))
        }
        else {
            return (1 << i)
        }
    }
    
    return 1
}
