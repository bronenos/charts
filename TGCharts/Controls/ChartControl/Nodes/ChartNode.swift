//
//  ChartNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartNode: class {
    var origin: CGPoint { get }
    var size: CGSize { get }
    var bounds: CGRect { get }
    func addChild(node: IChartNode)
    func removeAllChildren()
    func renderWithChildren(graphics: IGraphics)
    func render(graphics: IGraphics)
    func setFrame(_ frame: CGRect)
    func setBackgroundColor(_ color: UIColor)
}

class ChartNode: IChartNode {
    private var frame = CGRect.zero
    private var childNodes = [IChartNode]()
    private var backgroundColor = UIColor.clear
    
    var origin: CGPoint {
        return frame.origin
    }
    
    var size: CGSize {
        return frame.size
    }
    
    var bounds: CGRect {
        return CGRect(origin: .zero, size: size)
    }
    
    final func addChild(node: IChartNode) {
        childNodes.append(node)
    }
    
    final func removeAllChildren() {
        childNodes.removeAll()
    }
    
    final func renderWithChildren(graphics: IGraphics) {
        render(graphics: graphics)
        
        childNodes.forEach { childNode in
            graphics.pushOffset(childNode.origin)
            childNode.renderWithChildren(graphics: graphics)
            graphics.popOffset()
        }
    }
    
    func render(graphics: IGraphics) {
        let rect = CGRect(origin: .zero, size: size)
        graphics.fill(frame: rect, color: backgroundColor)
    }

    func setFrame(_ frame: CGRect) {
        self.frame = frame
    }
    
    final func setBackgroundColor(_ color: UIColor) {
        backgroundColor = color
    }
}
