//
//  ChartVerticalStepNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 21/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartVerticalStepNode: IChartNode {
    var value: String { get set }
}

final class ChartVerticalStepNode: ChartNode, IChartVerticalStepNode {
    private let valueNode: IChartLabelNode = ChartLabelNode(tag: "step-value")
    private let underlineNode: IChartNode = ChartNode(tag: "step-underline")
    
    override init(tag: String) {
        super.init(tag: tag)
        
        addChild(node: valueNode)
        
        addChild(node: underlineNode)
    }
    
    override var frame: CGRect {
        didSet { layoutChildren() }
    }
    
    var value = String() {
        didSet {
            valueNode.content = ChartLabelNodeContent(
                text: value,
                color: DesignBook.shared.color(.chartIndexForeground),
                font: UIFont.systemFont(ofSize: 12),
                alignment: .left,
                limitedToBounds: true
            )
            
            layoutChildren()
        }
    }
    
    var color: UIColor {
        get { return underlineNode.backgroundColor }
        set { underlineNode.backgroundColor = newValue }
    }
    
    private func layoutChildren() {
        let layout = Layout(
            bounds: bounds,
            valueNode: valueNode,
            underlineNode: underlineNode
        )
        
        valueNode.frame = layout.valueNodeFrame
        underlineNode.frame = layout.underlineNodeFrame
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let valueNode: IChartLabelNode
    let underlineNode: IChartNode

    private let underlineHeight = CGFloat(1)
    
    var valueNodeFrame: CGRect {
        let size = valueNode.calculateSize()
        return CGRect(x: 0, y: 0, width: size.width, height: bounds.height)
    }
    
    var underlineNodeFrame: CGRect {
        return bounds.divided(atDistance: 1, from: .minYEdge).slice
    }
}
