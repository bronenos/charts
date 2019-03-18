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
    var timelineNode: IChartTimelineNode { get }
    var navigatorNode: IChartNavigatorNode { get }
    func setChart(_ chart: Chart, config: ChartConfig)
}

protocol IChartSceneDelegate: class {
}

final class ChartSceneNode: ChartNode, IChartSceneNode {
    let graphNode: IChartGraphNode
    let timelineNode: IChartTimelineNode
    let navigatorNode: IChartNavigatorNode
    
    init(tag: String?, formattingProvider: IFormattingProvider) {
        graphNode = ChartGraphNode(tag: "graph", width: 2)
        timelineNode = ChartTimelineNode(tag: "timeline", formattingProvider: formattingProvider)
        navigatorNode = ChartNavigatorNode(tag: "navigator")

        super.init(tag: tag ?? "[scene]")
        
        addChild(node: graphNode)
        addChild(node: timelineNode)
        addChild(node: navigatorNode)
    }
    
    override var frame: CGRect {
        didSet { layoutChildren() }
    }
    
    override func node(at point: CGPoint) -> IChartNode? {
        let flippedPoint = CGPoint(x: point.x, y: size.height - point.y)
        return super.node(at: flippedPoint)
    }
    
    override func render(graphics: IGraphics) {
        graphics.clear(color: backgroundColor)
        super.render(graphics: graphics)
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        graphNode.setChart(chart, config: config)
        timelineNode.setChart(chart, config: config)
        navigatorNode.setChart(chart, config: config)
    }
    
    private func layoutChildren() {
        let layout = Layout(bounds: bounds)
        graphNode.frame = layout.graphNodeFrame
        timelineNode.frame = layout.timelineFrame
        navigatorNode.frame = layout.navigatorFrame
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    
    private let timelineHeight = CGFloat(25)
    private let navigatorHeight = CGFloat(40)
    
    var graphNodeFrame: CGRect {
        let height = bounds.height - timelineFrame.maxY
        return CGRect(x: 0, y: timelineFrame.maxY, width: bounds.width, height: height)
    }
    
    var timelineFrame: CGRect {
        return CGRect(x: 0, y: navigatorFrame.maxY, width: bounds.width, height: timelineHeight)
    }
    
    var navigatorFrame: CGRect {
        return CGRect(x: 0, y: 0, width: bounds.width, height: navigatorHeight)
    }
}
