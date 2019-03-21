//
//  ChartNavigatorNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartNavigatorNode: IChartNode {
    var canvasNode: IChartNode { get }
    var graphNode: IChartGraphNode { get }
    var sliderNode: IChartSliderNode { get }
    func setChart(_ chart: Chart, config: ChartConfig)
}

final class ChartNavigatorNode: ChartNode, IChartNavigatorNode {
    let canvasNode: IChartNode = ChartNode(tag: "navigator-canvas")
    let graphNode: IChartGraphNode = ChartGraphNode(tag: "navigator-graph", width: 1)
    let sliderNode: IChartSliderNode = ChartSliderNode(tag: "navigator-slider")
    
    private var range = ChartRange(start: 0, end: 1.0)
    
    override init(tag: String?) {
        super.init(tag: tag ?? "[navigator]")
        
        addChild(node: canvasNode)
        addChild(node: graphNode)
        addChild(node: sliderNode)
    }
    
    override var frame: CGRect {
        didSet { update(range: range) }
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        self.range = config.range
        
        graphNode.setChart(chart, config: config.fullRanged(), sideOverlap: 0)
        update(range: config.range)
    }
    
    override func render(graphics: IGraphics) -> Bool {
        backgroundColor = DesignBook.shared.color(.navigatorBackground)
        
        return super.render(graphics: graphics)
    }
    
    private func update(range: ChartRange) {
        let sliderLeftX = size.width * range.start - sliderNode.horizontalGap
        let sliderWidth = size.width * range.distance + sliderNode.horizontalGap * 2
        let sliderFrame = CGRect(x: sliderLeftX, y: 0, width: sliderWidth, height: size.height)
        canvasNode.frame = sliderFrame
        sliderNode.frame = sliderFrame
        
        let graphFrame = CGRect(origin: .zero, size: size).insetBy(dx: 0, dy: sliderNode.verticalGap)
        graphNode.frame = graphFrame
    }
}
