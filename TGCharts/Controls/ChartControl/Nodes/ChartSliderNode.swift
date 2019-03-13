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
    var leftCaptionNode: ChartFigureNode { get }
    var rightCaptionNode: ChartFigureNode { get }
    func setControlBackgroundColor(_ color: UIColor)
    func setControlForegroundColor(_ color: UIColor)
}

final class ChartSliderNode: ChartNode, IChartSliderNode {
    let leftCaptionNode = ChartFigureNode()
    let rightCaptionNode = ChartFigureNode()
    
    private var controlBackgroundColor = UIColor.clear

    private let horizontalGap = CGFloat(10)
    private let verticalGap = CGFloat(1)
    
    override init() {
        super.init()
        
        leftCaptionNode.setWidth(1)
        addChild(node: leftCaptionNode)
        
        rightCaptionNode.setWidth(1)
        addChild(node: rightCaptionNode)
    }
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        
        let leftGapFrame = bounds.divided(atDistance: horizontalGap, from: .minXEdge).slice
        leftCaptionNode.setPoints(
            [
                leftGapFrame.offsetBy(dx: 1, dy: 3).center,
                leftGapFrame.offsetBy(dx: -1, dy: 0).center,
                leftGapFrame.offsetBy(dx: 1, dy: -3).center
            ]
        )
        
        let rightGapFrame = bounds.divided(atDistance: horizontalGap, from: .maxXEdge).slice
        rightCaptionNode.setPoints(
            [
                rightGapFrame.offsetBy(dx: -1, dy: 3).center,
                rightGapFrame.offsetBy(dx: 1, dy: 0).center,
                rightGapFrame.offsetBy(dx: -1, dy: -3).center
            ]
        )
    }

    func setControlBackgroundColor(_ color: UIColor) {
        controlBackgroundColor = color
    }
    
    func setControlForegroundColor(_ color: UIColor) {
        leftCaptionNode.setStrokeColor(color)
        rightCaptionNode.setStrokeColor(color)
    }
    
    override func render(graphics: IGraphics) {
        super.render(graphics: graphics)
        
        let leftGapFrame = bounds.divided(atDistance: horizontalGap, from: .minXEdge).slice
        graphics.fill(frame: leftGapFrame, color: controlBackgroundColor)
        
        let rightGapFrame = bounds.divided(atDistance: horizontalGap, from: .maxXEdge).slice
        graphics.fill(frame: rightGapFrame, color: controlBackgroundColor)
        
        let bottomGapFrame = bounds.divided(atDistance: verticalGap, from: .minYEdge).slice
        graphics.fill(frame: bottomGapFrame, color: controlBackgroundColor)
        
        let topGapFrame = bounds.divided(atDistance: verticalGap, from: .maxYEdge).slice
        graphics.fill(frame: topGapFrame, color: controlBackgroundColor)
    }
}
