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
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        
        update(range: range)
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        self.range = config.range
        
        graphNode.setChart(chart, config: config.fullRanged())
        update(range: config.range)
    }
    
    private func update(range: ChartRange) {
        let canvasLeftX = size.width * range.start.toFloat
        let canvasWidth = size.width * range.distance.toFloat
        let canvasFrame = CGRect(x: canvasLeftX, y: 0, width: canvasWidth, height: size.height)
        canvasNode.setFrame(canvasFrame)
        
        let graphFrame = CGRect(origin: .zero, size: size).insetBy(dx: 0, dy: 1)
        graphNode.setFrame(graphFrame)
        
        let sliderFrame = canvasFrame
        sliderNode.setFrame(sliderFrame)
    }
}
