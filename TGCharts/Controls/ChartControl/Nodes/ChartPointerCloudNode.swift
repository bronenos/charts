//
//  ChartPointerCloudNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 19/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartPointerCloudNode: IChartNode {
    var overlayNode: IChartFigureNode { get }
    var dateNode: IChartLabelNode { get }
    var yearNode: IChartLabelNode { get }
    var valuesFont: UIFont { get set }
    func setDate(_ date: Date, lines: [ChartLine], index: Int)
}

final class ChartPointerCloudNode: ChartNode, IChartPointerCloudNode {
    private let formattingProvider: IFormattingProvider
    
    let overlayNode: IChartFigureNode = ChartFigureNode(tag: "pointer-overlay")
    let dateNode: IChartLabelNode = ChartLabelNode(tag: "pointer-date")
    let yearNode: IChartLabelNode = ChartLabelNode(tag: "pointer-year")
    var valuesFont = UIFont.systemFont(ofSize: 12)

    private var valueNodes = [IChartLabelNode]()
    
    init(tag: String, formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        super.init(tag: tag)
        
        overlayNode.figure = .roundedSquare
        overlayNode.color = DesignBook.shared.resolve(colorAlias: .chartGridBackground)
        overlayNode.radius = 4
        
        addChild(node: overlayNode)
        overlayNode.addChild(node: dateNode)
        overlayNode.addChild(node: yearNode)
    }
    
    override var frame: CGRect {
        didSet { layoutChildren() }
    }
    
    func setDate(_ date: Date, lines: [ChartLine], index: Int) {
        valueNodes.forEach { $0.removeFromParent() }
        valueNodes = lines.map { constructValueNode(line: $0, index: index) }
        valueNodes.forEach { overlayNode.addChild(node: $0) }
        
        dateNode.content = ChartLabelNodeContent(
            text: "\(formattingProvider.format(date: date, style: .shortDate))",
            color: DesignBook.shared.resolve(colorAlias: .chartPointerForeground),
            font: UIFont.boldSystemFont(ofSize: 12),
            alignment: .left,
            limitedToBounds: false
        )
        
        yearNode.content = ChartLabelNodeContent(
            text: "\(formattingProvider.format(date: date, style: .justYear))",
            color: DesignBook.shared.resolve(colorAlias: .chartPointerForeground),
            font: UIFont.systemFont(ofSize: 12),
            alignment: .left,
            limitedToBounds: false
        )
        
        layoutChildren()
    }
    
    private func layoutChildren() {
        let layout = Layout(
            bounds: bounds,
            overlayNode: overlayNode,
            dateNode: dateNode,
            yearNode: yearNode,
            valueNodes: valueNodes
        )
        
        overlayNode.frame = layout.overlayNodeFrame
        dateNode.frame = layout.dateNodeFrame
        yearNode.frame = layout.yearNodeFrame
        zip(valueNodes, layout.valueNodeFrames).forEach { node, nodeFrame in node.frame = nodeFrame }
    }
    
    private func constructValueNode(line: ChartLine, index: Int) -> IChartLabelNode {
        let content = ChartLabelNodeContent(
            text: "\(line.values[index])",
            color: line.color,
            font: UIFont.systemFont(ofSize: 12),
            alignment: .right,
            limitedToBounds: false
        )
        
        let valueNode = ChartLabelNode(tag: "pointer-value")
        valueNode.content = content
        return valueNode
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let overlayNode: IChartFigureNode
    let dateNode: IChartLabelNode
    let yearNode: IChartLabelNode
    let valueNodes: [IChartLabelNode]
    
    private let horGap = CGFloat(7)
    private let verGap = CGFloat(5)
    private let innerGap = CGFloat(15)
    
    var overlayNodeFrame: CGRect {
        let leftLaneHeight = dateNode.calculateSize().height + verGap + yearNode.calculateSize().height
        let rightLaneHeight = valuesHeight + CGFloat(valueNodes.count) * verGap
        let height = verGap + max(leftLaneHeight, rightLaneHeight) + verGap
        return CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
    }
    
    var dateNodeFrame: CGRect {
        let size = dateNode.calculateSize()
        return CGRect(x: horGap, y: verGap, width: size.width, height: size.height)
    }

    var yearNodeFrame: CGRect {
        let size = yearNode.calculateSize()
        let topY = dateNodeFrame.maxY + verGap
        return CGRect(x: horGap, y: topY, width: size.width, height: size.height)
    }
    
    var valueNodeFrames: [CGRect] {
        var topY = verGap
        return valueNodes.map { node in
            let size = node.calculateSize()
            defer { topY += size.height + verGap }
            
            let leftX = bounds.width - horGap - size.width
            return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        }
    }
    
    private var valuesNodeSizes: [CGSize] {
        return valueNodes.map { $0.calculateSize() }
    }
    
    private var valuesMaxWidth: CGFloat {
        return valuesNodeSizes.map({ $0.width }).max() ?? 0
    }
    
    private var valuesHeight: CGFloat {
        return valuesNodeSizes.map({ $0.height }).reduce(0, +)
    }
    
    private var contentWidth: CGFloat {
        let dateWidth = dateNode.calculateSize().width
        let yearWidth = yearNode.calculateSize().width
        return horGap + max(dateWidth, yearWidth) + innerGap + valuesMaxWidth + horGap
    }
}
