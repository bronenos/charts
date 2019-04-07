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
    func update(config: ChartConfig, duration: TimeInterval)
}

final class ChartNavigatorNode: ChartNode, IChartNavigatorNode {
    let backDim = ChartNode()
    let spaceNode = ChartNode()
    let graphNode: ChartGraphNode
    let leftDim = ChartNode()
    let rightDim = ChartNode()
    let sliderNode = ChartSliderNode()
    
    private var range: ChartRange
    
    init(chart: Chart, config: ChartConfig) {
        self.range = config.range

        graphNode = ChartGraphNode(chart: chart, config: config.fullRanged(), width: 1)
        
        super.init(frame: .zero)
        
        tag = ChartControlTag.navigator.rawValue
        clipsToBounds = true
        
        addSubview(backDim)
        addSubview(spaceNode)
        addSubview(graphNode)
        addSubview(leftDim)
        addSubview(rightDim)
        addSubview(sliderNode)
        
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.range = config.range
        
        graphNode.update(config: config.fullRanged(), duration: duration)
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
        graphNode.updateDesign()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let graphFrame = CGRect(origin: .zero, size: bounds.size).insetBy(dx: 0, dy: sliderNode.verticalGap * 2)
        let sliderLeftX = bounds.size.width * range.start
        let sliderWidth = bounds.size.width * range.distance
        let sliderFrame = CGRect(x: sliderLeftX, y: 0, width: sliderWidth, height: bounds.size.height)
        
        backDim.frame = graphFrame
        spaceNode.frame = sliderFrame
        graphNode.frame = graphFrame
        leftDim.frame = bounds.divided(atDistance: sliderLeftX, from: .minXEdge).slice
        rightDim.frame = bounds.divided(atDistance: sliderLeftX + sliderWidth, from: .minXEdge).remainder
        sliderNode.frame = sliderFrame
    }
}
