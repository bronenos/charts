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
    var color: UIColor? { get set }
}

final class ChartVerticalStepNode: ChartNode, IChartVerticalStepNode {
    enum Mode {
        case value
        case underline
    }
    
    private let valueNode = ChartLabelNode()
    private let underlineNode = ChartNode()
    
    init(mode: Mode) {
        super.init(frame: .zero)
        
        isUserInteractionEnabled = false
        
        switch mode {
        case .value: addSubview(valueNode)
        case .underline: addSubview(underlineNode)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
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
            
            setNeedsLayout()
        }
    }
    
    var color: UIColor? {
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
        let size = valueNode.sizeThatFits(.zero)
        return CGRect(x: 0, y: 0, width: size.width, height: bounds.height)
    }
    
    var underlineNodeFrame: CGRect {
        return bounds.divided(atDistance: 1, from: .maxYEdge).slice
    }
}
