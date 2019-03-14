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
    func setChart(_ chart: StatChart, config: ChartConfig, range: ChartRange)
}

final class ChartNavigatorNode: ChartNode, IChartNavigatorNode {
    let canvasNode: IChartNode = ChartNode(tag: "navigator-canvas")
    let graphNode: IChartGraphNode = ChartGraphNode(tag: "navigator-graph")
    let sliderNode: IChartSliderNode = ChartSliderNode(tag: "navigator-slider")
    
    private var range = ChartRange.full
    
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
    
    func setChart(_ chart: StatChart, config: ChartConfig, range: ChartRange) {
        self.range = range
        
        graphNode.setChart(chart, config: config, range: ChartRange.full)
        update(range: range)
    }
    
    private func update(range: ChartRange) {
        let canvasFrame = CGRect(x: size.width * range.start, y: 0, width: size.width * range.distance, height: size.height)
        canvasNode.setFrame(canvasFrame)
        
        let graphFrame = CGRect(origin: .zero, size: size).insetBy(dx: 0, dy: 1)
        graphNode.setFrame(graphFrame)
        
        let sliderFrame = canvasFrame
        sliderNode.setFrame(sliderFrame)
    }
}