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
    var delegate: IChartSceneDelegate? { get set }
    var graphNode: IChartMainGraphNode { get }
    var timelineNode: IChartTimelineNode { get }
    var navigatorNode: IChartNavigatorNode { get }
    func setChart(_ chart: Chart, config: ChartConfig)
    func updateChart(_ chart: Chart, config: ChartConfig)
}

protocol IChartSceneDelegate: class {
    func sceneDidRequestAnimatedRendering(duration: TimeInterval)
}

final class ChartSceneNode: ChartNode, IChartSceneNode {
    weak var delegate: IChartSceneDelegate?
    
    let graphNode: IChartMainGraphNode
    let timelineNode: IChartTimelineNode
    let navigatorNode: IChartNavigatorNode
    
    private var config = ChartConfig(lines: [], range: ChartRange(start: 0, end: 0), pointer: nil)
    
    init(tag: String?, formattingProvider: IFormattingProvider) {
        graphNode = ChartMainGraphNode(tag: "graph", width: 2, formattingProvider: formattingProvider)
        timelineNode = ChartTimelineNode(tag: "timeline", formattingProvider: formattingProvider)
        navigatorNode = ChartNavigatorNode(tag: "navigator")

        super.init(tag: tag ?? "[scene]", cachable: false)
        
        addChild(node: graphNode)
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
        backgroundColor = DesignBook.shared.color(.primaryBackground)
        graphics.clear(color: backgroundColor)

        return super.render(graphics: graphics)
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        self.config = config
        
        graphNode.setChart(chart, config: config, overlap: Layout.totalGaps, duration: 0)
        timelineNode.setChart(chart, config: config, overlap: Layout.sideGaps, duration: 0)
        navigatorNode.setChart(chart, config: config, duration: 0)
        
        layoutChildren()
    }
    
    func updateChart(_ chart: Chart, config: ChartConfig) {
        self.config = config
        
        graphNode.setChart(chart, config: config, overlap: Layout.totalGaps, duration: 0.25)
        timelineNode.setChart(chart, config: config, overlap: Layout.sideGaps, duration: 0)
        navigatorNode.setChart(chart, config: config, duration: 0.25)
        
        layoutChildren()
    }
    
    override func prepareForAnimation(_ animation: IChartNodeAnimation) {
        let duration = animation.endTime.timeIntervalSince(Date())
        delegate?.sceneDidRequestAnimatedRendering(duration: duration)
    }
    
    private func layoutChildren() {
        let layout = Layout(bounds: bounds, config: config)
        graphNode.frame = layout.graphNodeFrame
        timelineNode.frame = layout.timelineFrame
        navigatorNode.frame = layout.navigatorFrame
    }
}

fileprivate struct Layout {
    static func gaps(bottom: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: bottom, right: 15)
    }
    
    static let totalGaps = Layout.gaps(bottom: 5)
    static let sideGaps = Layout.gaps(bottom: 0)

    let bounds: CGRect
    let config: ChartConfig
    
    private let gaps = Layout.totalGaps
    private let timelineHeight = CGFloat(25)
    private let navigatorHeight = CGFloat(40)
    
    var graphNodeFrame: CGRect {
        let leftX = gaps.left
        let width = bounds.width - gaps.right - leftX
        let height = bounds.height - timelineFrame.maxY - gaps.bottom
        return CGRect(x: leftX, y: timelineFrame.maxY, width: width, height: height)
    }
    
    var timelineFrame: CGRect {
        let leftX = gaps.left
        let width = bounds.width - gaps.right - leftX
        return CGRect(x: leftX, y: navigatorFrame.maxY, width: width, height: timelineHeight)
    }
    
    var navigatorFrame: CGRect {
        let leftX = gaps.left
        let width = bounds.width - gaps.right - leftX
        return CGRect(x: leftX, y: 0, width: width, height: navigatorHeight)
    }
}
