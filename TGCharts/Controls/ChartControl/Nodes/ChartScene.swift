//
//  ChartScene.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartSceneNode: IChartNode {
    var graphNode: IChartGraphNode { get }
    var pointerNode: IChartPointerNode { get }
    var timelineNode: IChartTimelineNode { get }
    var navigatorNode: IChartNavigatorNode { get }
    func setChart(_ chart: Chart, config: ChartConfig)
}

protocol IChartSceneDelegate: class {
}

final class ChartSceneNode: ChartNode, IChartSceneNode {
    let graphNode: IChartGraphNode
    let pointerNode: IChartPointerNode
    let timelineNode: IChartTimelineNode
    let navigatorNode: IChartNavigatorNode
    
    private var config = ChartConfig(lines: [], range: ChartRange(start: 0, end: 0), pointer: nil)
    
    init(tag: String?, formattingProvider: IFormattingProvider) {
        graphNode = ChartGraphNode(tag: "graph", width: 2)
        pointerNode = ChartPointerNode(tag: "pointer", formattingProvider: formattingProvider)
        timelineNode = ChartTimelineNode(tag: "timeline", formattingProvider: formattingProvider)
        navigatorNode = ChartNavigatorNode(tag: "navigator")

        super.init(tag: tag ?? "[scene]")
        
        addChild(node: graphNode)
        addChild(node: pointerNode)
        addChild(node: timelineNode)
        addChild(node: navigatorNode)
    }
    
    override var frame: CGRect {
        didSet { layoutChildren() }
    }
    
    override func node(at point: CGPoint, interactable: Bool) -> IChartNode? {
        let flippedPoint = CGPoint(x: point.x, y: size.height - point.y)
        return super.node(at: flippedPoint, interactable: interactable)
    }
    
    override func render(graphics: IGraphics) -> Bool {
        graphics.clear(color: backgroundColor)
        
        guard super.render(graphics: graphics) else { return false }
        return true
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        self.config = config
        
        graphNode.setChart(chart, config: config, sideOverlap: Layout.sideGap)
        timelineNode.setChart(chart, config: config, sideOverlap: Layout.sideGap)
        navigatorNode.setChart(chart, config: config)
        
        if let pointer = config.pointer {
            let index = Int(CGFloat(chart.length - 1) * pointer)
            let date = chart.axis[index].date
            let lines = chart.visibleLines(config: config)
            
            pointerNode.setDate(date, lines: lines, index: index)
            pointerNode.alpha = 1.0
        }
        else {
            pointerNode.alpha = 0
        }
        
        layoutChildren()
    }
    
    private func layoutChildren() {
        let layout = Layout(bounds: bounds, config: config)
        graphNode.frame = layout.graphNodeFrame
        pointerNode.frame = layout.pointerNodeFrame
        timelineNode.frame = layout.timelineFrame
        navigatorNode.frame = layout.navigatorFrame
    }
}

fileprivate struct Layout {
    static let sideGap = CGFloat(15)
    
    let bounds: CGRect
    let config: ChartConfig
    
    private let sideGap = Layout.sideGap
    private let pointerWidth = CGFloat(90)
    private let timelineHeight = CGFloat(25)
    private let navigatorHeight = CGFloat(40)
    
    var graphNodeFrame: CGRect {
        let height = bounds.height - timelineFrame.maxY - 5
        let base = CGRect(x: 0, y: timelineFrame.maxY, width: bounds.width, height: height)
        return base.insetBy(dx: sideGap, dy: 0)
    }
    
    var pointerNodeFrame: CGRect {
        if let pointer = config.pointer {
            let clamped = (pointer - config.range.start) / config.range.distance
            let topY = timelineFrame.maxY
            let leftX = sideGap + (graphNodeFrame.width - pointerWidth) * clamped
            return CGRect(x: leftX, y: topY, width: pointerWidth, height: graphNodeFrame.height)
        }
        else {
            return .zero
        }
    }
    
    var timelineFrame: CGRect {
        let base = CGRect(x: 0, y: navigatorFrame.maxY, width: bounds.width, height: timelineHeight)
        return base.insetBy(dx: sideGap, dy: 0)
    }
    
    var navigatorFrame: CGRect {
        let base = CGRect(x: 0, y: 0, width: bounds.width, height: navigatorHeight)
        return base.insetBy(dx: sideGap, dy: 0)
    }
}
