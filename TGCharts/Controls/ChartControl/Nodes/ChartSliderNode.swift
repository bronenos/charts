//
//  ChartSliderNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartSliderNode: IChartNode {
    var leftArrowNode: ChartSliderArrowNode { get }
    var rightArrowNode: ChartSliderArrowNode { get }
}

final class ChartSliderNode: ChartNode, IChartSliderNode {
    let leftArrowNode = ChartSliderArrowNode(tag: "slider-left-arrow", direction: .left)
    let rightArrowNode = ChartSliderArrowNode(tag: "slider-right-arrow", direction: .right)
    
    private let horizontalGap = CGFloat(10)
    private let verticalGap = CGFloat(1)
    
    override init(tag: String?) {
        super.init(tag: tag ?? "[slider]")
        
        addChild(node: leftArrowNode)
        addChild(node: rightArrowNode)
    }
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        
        let leftGapFrame = bounds.divided(atDistance: horizontalGap, from: .minXEdge).slice
        leftArrowNode.setFrame(leftGapFrame)
        
        let rightGapFrame = bounds.divided(atDistance: horizontalGap, from: .maxXEdge).slice
        rightArrowNode.setFrame(rightGapFrame)
    }

    override func render(graphics: IGraphics) {
        // prevent the entire filling
        // super.render(graphics: graphics)
        
        let leftGapFrame = bounds.divided(atDistance: horizontalGap, from: .minXEdge).slice
        graphics.fill(frame: leftGapFrame, color: foregroundColor)
        
        let rightGapFrame = bounds.divided(atDistance: horizontalGap, from: .maxXEdge).slice
        graphics.fill(frame: rightGapFrame, color: foregroundColor)
        
        let bottomGapFrame = bounds.divided(atDistance: verticalGap, from: .minYEdge).slice
        graphics.fill(frame: bottomGapFrame, color: foregroundColor)
        
        let topGapFrame = bounds.divided(atDistance: verticalGap, from: .maxYEdge).slice
        graphics.fill(frame: topGapFrame, color: foregroundColor)
    }
}
