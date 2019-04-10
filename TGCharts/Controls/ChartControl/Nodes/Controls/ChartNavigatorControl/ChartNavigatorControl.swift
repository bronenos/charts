//
//  ChartNavigatorControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartNavigatorControl: IChartNode {
    func inject(graph: ChartGraphNode)
    func update(config: ChartConfig, duration: TimeInterval)
}

final class ChartNavigatorControl: ChartNode, IChartNavigatorControl {
    let backDim = ChartNode()
    let spaceNode = ChartNode()
    let graphContainer: ChartGraphContainer
    let leftDim = ChartNode()
    let rightDim = ChartNode()
    let sliderNode = ChartSliderNode()
    
    private var range: ChartRange
    private var currentGraph: ChartGraphNode?

    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        self.range = config.range

        graphContainer = ChartGraphContainer(chart: chart, config: config.fullRanged(), formattingProvider: formattingProvider, enableControls: false)
        
        super.init(frame: .zero)
        
        tag = ChartControlTag.navigator.rawValue
        clipsToBounds = true
        
        addSubview(backDim)
        addSubview(spaceNode)
        addSubview(graphContainer)
        addSubview(leftDim)
        addSubview(rightDim)
        addSubview(sliderNode)
        
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func inject(graph: ChartGraphNode) {
        currentGraph = graph
        graphContainer.inject(graph: graph)
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.range = config.range
        
        currentGraph?.update(config: config.fullRanged(), duration: duration)
        sliderNode.setNeedsLayout()
        
        setNeedsLayout()
    }
    
    override func updateDesign() {
        super.updateDesign()
        backDim.backgroundColor = DesignBook.shared.color(.navigatorBackground)
        spaceNode.backgroundColor = DesignBook.shared.color(.primaryBackground)
        leftDim.backgroundColor = DesignBook.shared.color(.navigatorCoverBackground)
        rightDim.backgroundColor = DesignBook.shared.color(.navigatorCoverBackground)
        sliderNode.updateDesign()
        graphContainer.updateDesign()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let graphFrame = CGRect(origin: .zero, size: bounds.size).insetBy(dx: 0, dy: sliderNode.verticalGap * 2)
        let sliderLeftX = bounds.size.width * range.start
        let sliderWidth = bounds.size.width * range.distance
        let sliderFrame = CGRect(x: sliderLeftX, y: 0, width: sliderWidth, height: bounds.size.height)
        
        backDim.frame = graphFrame
        spaceNode.frame = sliderFrame
        graphContainer.frame = graphFrame
        leftDim.frame = bounds.divided(atDistance: sliderLeftX, from: .minXEdge).slice
        rightDim.frame = bounds.divided(atDistance: sliderLeftX + sliderWidth, from: .minXEdge).remainder
        sliderNode.frame = sliderFrame
    }
}
