//
//  ChartNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum ChartNodeTarget {
    case front
    case back
}

protocol IChartNode: class {
    var tag: String { get }
    var frame: CGRect { get set }
    var bounds: CGRect { get }
    var origin: CGPoint { get }
    var size: CGSize { get }
    var alpha: CGFloat { get set }
    var backgroundColor: UIColor { get set }
    var foregroundColor: UIColor { get set }
    var isInteractable: Bool { get set }
    var isDirty: Bool { get }
    var parentNode: IChartNode? { get }
    func addChild(node: IChartNode)
    func addChild(node: IChartNode, target: ChartNodeTarget)
    func moveChild(node: IChartNode, target: ChartNodeTarget)
    func assignToParent(node: IChartNode?)
    func removeFromParent()
    func removeAllChildren()
    func renderWithChildren(output: GraphicsOutputRef, graphics: IGraphics)
    func render(graphics: IGraphics) -> Bool
    func node(at point: CGPoint, interactable: Bool) -> IChartNode?
    func node(by tag: String) -> IChartNode?
    func dirtify()
    func calculateFullOrigin(of node: IChartNode) -> CGPoint?
}

class ChartNode: IChartNode {
    let tag: String
    let cachable: Bool
    
    var isInteractable = true
    
    private var cachedTexture: GraphicsTextureRef?

    private var childNodes = [IChartNode]()
    private(set) weak var parentNode: IChartNode?
    private(set) var isDirty = false

    init(tag: String, cachable: Bool) {
        self.tag = tag
        self.cachable = false // cachable
    }
    
    deinit {
        childNodes.forEach { $0.removeFromParent() }
    }
    
    var frame = CGRect.zero {
        didSet {
            guard frame != oldValue else { return }
            dirtify()
        }
    }
    
    var alpha = CGFloat(1.0) {
        didSet {
            guard alpha != oldValue else { return }
            dirtify()
        }
    }
    
    var backgroundColor = UIColor.clear {
        didSet {
            guard backgroundColor != oldValue else { return }
            dirtify()
        }
    }
    
    var foregroundColor = UIColor.clear {
        didSet {
            guard foregroundColor != oldValue else { return }
            dirtify()
        }
    }
    
    var bounds: CGRect {
        return CGRect(origin: .zero, size: size)
    }
    
    var origin: CGPoint {
        return frame.origin
    }
    
    var size: CGSize {
        return frame.size
    }
    
    final func addChild(node: IChartNode) {
        addChild(node: node, target: .front)
    }
    
    final func addChild(node: IChartNode, target: ChartNodeTarget) {
        guard node.parentNode !== self else { return }
        node.assignToParent(node: self)

        switch target {
        case .front: childNodes.append(node)
        case .back: childNodes.insert(node, at: 0)
        }
    }
    
    final func moveChild(node: IChartNode, target: ChartNodeTarget) {
        if node.parentNode === self {
            node.removeFromParent()
        }
        
        addChild(node: node, target: target)
    }
    
    final func assignToParent(node: IChartNode?) {
        parentNode = node
    }
    
    final func removeChild(node: IChartNode) {
        childNodes = childNodes.filter { $0 !== node }
        node.assignToParent(node: nil)
    }
    
    final func removeFromParent() {
        guard let parentNode = parentNode as? ChartNode else { return }
        parentNode.removeChild(node: self)
    }
    
    final func removeAllChildren() {
        childNodes.forEach { $0.assignToParent(node: nil) }
        childNodes.removeAll()
    }
    
    final func renderWithChildren(output: GraphicsOutputRef, graphics: IGraphics) {
        graphics.pushMarker(caption: tag)
        defer { graphics.popMarker() }
        
        if isDirty, cachable {
            if let texture = graphics.requestNodeTexture(size: size) {
                cachedTexture = texture
                
                defer {
                    graphics.flushNodeTexture(texture)
                    graphics.drawNodeTexture(texture: texture)
                    isDirty = false
                }

                if !render(graphics: graphics) {
                    return
                }
            }
            else if !render(graphics: graphics) {
                return
            }
        }
        else if let texture = cachedTexture {
            graphics.drawNodeTexture(texture: texture)
        }
        else if !render(graphics: graphics) {
            return
        }

        childNodes.forEach { childNode in
            graphics.pushOffset(childNode.origin)
            childNode.renderWithChildren(output: output, graphics: graphics)
            graphics.popOffset()
        }
    }
    
    func render(graphics: IGraphics) -> Bool {
        guard alpha > 0 else { return false }
        
        let rect = CGRect(origin: .zero, size: size)
        graphics.fill(frame: rect, color: backgroundColor)
        return true
    }

    func node(at point: CGPoint, interactable: Bool) -> IChartNode? {
        for childNode in childNodes.reversed() {
            let childPoint = CGPoint(point - childNode.origin)
            guard let foundNode = childNode.node(at: childPoint, interactable: interactable) else { continue }
            return foundNode
        }
        
        if bounds.contains(point), (isInteractable || !interactable) {
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
    
    func dirtify() {
        guard cachable else { return }
        isDirty = true
        cachedTexture = nil
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
