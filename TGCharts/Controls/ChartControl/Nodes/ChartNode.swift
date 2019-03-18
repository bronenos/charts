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
    var tag: String { get }
    var frame: CGRect { get set }
    var bounds: CGRect { get }
    var origin: CGPoint { get }
    var size: CGSize { get }
    var alpha: CGFloat { get set }
    var backgroundColor: UIColor { get set }
    var foregroundColor: UIColor { get set }
    var parentNode: IChartNode? { get }
    func addChild(node: IChartNode)
    func assignToParent(node: IChartNode?)
    func removeAllChildren()
    func renderWithChildren(graphics: IGraphics)
    func render(graphics: IGraphics)
    func node(at point: CGPoint) -> IChartNode?
    func node(by tag: String) -> IChartNode?
    func calculateFullOrigin(of node: IChartNode) -> CGPoint?
}

class ChartNode: IChartNode {
    let tag: String
    
    var frame = CGRect.zero
    var alpha = CGFloat(1.0)
    var backgroundColor = UIColor.clear
    var foregroundColor = UIColor.clear
    
    private var childNodes = [IChartNode]()

    var bounds: CGRect {
        return CGRect(origin: .zero, size: size)
    }
    
    var origin: CGPoint {
        return frame.origin
    }
    
    var size: CGSize {
        return frame.size
    }
    
    private(set) weak var parentNode: IChartNode?
    
    init(tag: String) {
        self.tag = tag
    }
    
    final func addChild(node: IChartNode) {
        childNodes.append(node)
        node.assignToParent(node: self)
    }
    
    final func assignToParent(node: IChartNode?) {
        parentNode = node
    }
    
    final func removeAllChildren() {
        childNodes.forEach { $0.assignToParent(node: nil) }
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

    func node(at point: CGPoint) -> IChartNode? {
        for childNode in childNodes.reversed() {
            let childPoint = CGPoint(point - childNode.origin)
            guard let foundNode = childNode.node(at: childPoint) else { continue }
            return foundNode
        }
        
        if bounds.contains(point) {
            return self
        }
        
        return nil
    }
    
    func node(by tag: String) -> IChartNode? {
        if self.tag == tag {
            return self
        }
        
        for childNode in childNodes {
            guard let foundNode = childNode.node(by: tag) else { continue }
            return foundNode
        }
        
        return nil
    }
    
    func calculateFullOrigin(of node: IChartNode) -> CGPoint? {
        var currentNode = node
        var fullOrigin = CGVector(currentNode.origin)
        
        while true {
            guard let parentNode = currentNode.parentNode else {
                return nil
            }
            
            if parentNode === self  {
                return CGPoint(fullOrigin)
            }
            else {
                currentNode = parentNode
                fullOrigin += CGVector(currentNode.origin)
            }
        }
    }
}
