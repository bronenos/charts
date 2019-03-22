//
//  ChartVerticalStepNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 21/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum ChartVerticalStep {
    case value
    case line
}

protocol IChartVerticalStepNode: IChartNode {
    var value: String { get set }
    var color: UIColor { get set }
}

final class ChartVerticalStepNode: ChartNode, IChartVerticalStepNode {
    private let valueNode: IChartLabelNode = ChartLabelNode(tag: "step-value", cachable: false)
    private let underlineNode: IChartNode = ChartNode(tag: "step-underline", cachable: false)
    
    init(tag: String, step: ChartVerticalStep) {
        super.init(tag: tag, cachable: false)
        
        switch step {
        case .value: addChild(node: valueNode)
        case .line: addChild(node: underlineNode)
        }
    }
    
    override var frame: CGRect {
        didSet { layoutChildren() }
    }
    
    var value = String() {
        didSet {
            guard value != oldValue else { return }
            
            valueNode.content = ChartLabelNodeContent(
                text: value,
                color: DesignBook.shared.color(.chartIndexForeground),
                font: UIFont.systemFont(ofSize: 12),
                alignment: .left,
                limitedToBounds: false
            )
            
            layoutChildren()
        }
    }
    
    var color: UIColor {
        get {
            return underlineNode.backgroundColor
        }
        set {
            guard newValue != underlineNode.backgroundColor else { return }
            
            underlineNode.backgroundColor = newValue
            
            layoutChildren()
        }
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
