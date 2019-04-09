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
    var horizontalGap: CGFloat { get }
    var verticalGap: CGFloat { get }
    var leftArrowNode: ChartSliderArrowNode { get }
    var rightArrowNode: ChartSliderArrowNode { get }
}

final class ChartSliderNode: ChartFigureNode, IChartSliderNode {
    let horizontalGap = CGFloat(10)
    let verticalGap = CGFloat(1)
    
    let leftArrowNode = ChartSliderArrowNode(direction: .left)
    let rightArrowNode = ChartSliderArrowNode(direction: .right)
    
    init() {
        super.init(figure: .nestedBezierPaths)
        
        tag = ChartControlTag.slider.rawValue
        
        addSubview(leftArrowNode)
        addSubview(rightArrowNode)
        
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override func updateDesign() {
        super.updateDesign()
        fillColor = DesignBook.shared.color(.sliderBackground)
        leftArrowNode.updateDesign()
        rightArrowNode.updateDesign()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let outerPath = UIBezierPath(roundedRect: bounds, cornerRadius: 2)
        let innerPath = UIBezierPath(rect: bounds.insetBy(dx: horizontalGap, dy: verticalGap))
        bezierPaths = [outerPath, innerPath]
        
        leftArrowNode.frame = bounds.divided(atDistance: horizontalGap, from: .minXEdge).slice
        rightArrowNode.frame = bounds.divided(atDistance: horizontalGap, from: .maxXEdge).slice
    }
}
