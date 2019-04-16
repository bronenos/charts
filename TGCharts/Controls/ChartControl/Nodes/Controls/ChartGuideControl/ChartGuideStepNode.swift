//
//  ChartGuideStepNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 21/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGuideStepNode: IChartNode {
    var value: String? { get set }
    var valueColor: UIColor? { get set }
    var underlineColor: UIColor? { get set }
}

final class ChartGuideStepNode: ChartNode, IChartGuideStepNode {
    private let valueNode = ChartLabelNode()
    private let underlineNode = ChartNode()
    
    init(alignment: NSTextAlignment) {
        super.init(frame: .zero)
        
        isUserInteractionEnabled = false
        
        valueNode.font = DesignBook.shared.font(size: 10, weight: .regular)
        valueNode.textAlignment = alignment
        addSubview(valueNode)
        
        addSubview(underlineNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    var value: String? {
        get { return valueNode.text }
        set { valueNode.text = newValue }
    }
    
    var valueColor: UIColor? {
        get { return valueNode.textColor }
        set { valueNode.textColor = newValue }
    }
    
    var underlineColor: UIColor? {
        get { return underlineNode.backgroundColor }
        set { underlineNode.backgroundColor = newValue }
    }
    
    override func layoutSubviews() {
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
    let valueNode: ChartLabelNode
    let underlineNode: ChartNode

    private let underlineHeight = CGFloat(1)
    
    var valueNodeFrame: CGRect {
        return bounds
    }
    
    var underlineNodeFrame: CGRect {
        return bounds.divided(atDistance: 1, from: .maxYEdge).slice
    }
}
