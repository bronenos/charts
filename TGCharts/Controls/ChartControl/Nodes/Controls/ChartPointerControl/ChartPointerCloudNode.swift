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
    func setDate(_ date: Date, lines: [ChartLine], index: Int)
}

final class ChartPointerCloudNode: ChartNode, IChartPointerCloudNode {
    private let formattingProvider: IFormattingProvider
    
    let overlayNode = ChartFigureNode(figure: .roundedSquare)
    let dateNode = ChartLabelNode()
    let yearNode = ChartLabelNode()

    private var valueNodes = [ChartLabelNode]()
    
    init(formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        super.init(frame: .zero)
        
        overlayNode.radius = 4
        
        addSubview(overlayNode)
        
        dateNode.font = DesignBook.shared.font(size: 12, weight: .medium)
        dateNode.textAlignment = .left
        overlayNode.addSubview(dateNode)
        
        yearNode.font = DesignBook.shared.font(size: 12, weight: .medium)
        yearNode.textAlignment = .left
        overlayNode.addSubview(yearNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func setDate(_ date: Date, lines: [ChartLine], index: Int) {
        overlayNode.fillColor = DesignBook.shared.color(.chartPointerCloudBackground)
        
        valueNodes.forEach { $0.removeFromSuperview() }
        valueNodes = lines.map { constructValueNode(line: $0, index: index) }
        valueNodes.forEach { overlayNode.addSubview($0) }
        
        dateNode.text = formattingProvider.format(date: date, style: .shortDate)
        dateNode.textColor = DesignBook.shared.color(.chartPointerCloudForeground)
        
        yearNode.text = formattingProvider.format(date: date, style: .justYear)
        yearNode.textColor = DesignBook.shared.color(.chartPointerCloudForeground)
        
        setNeedsLayout()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        overlayNode.frame = layout.overlayNodeFrame
        dateNode.frame = layout.dateNodeFrame
        yearNode.frame = layout.yearNodeFrame
        zip(valueNodes, layout.valueNodeFrames).forEach { node, nodeFrame in node.frame = nodeFrame }
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            overlayNode: overlayNode,
            dateNode: dateNode,
            yearNode: yearNode,
            valueNodes: valueNodes
        )
    }
    
    private func constructValueNode(line: ChartLine, index: Int) -> ChartLabelNode {
        let valueNode = ChartLabelNode()
        valueNode.text = "\(line.values[index])"
        valueNode.textColor = line.color
        valueNode.font = DesignBook.shared.font(size: 12, weight: .regular)
        valueNode.textAlignment = .right
        return valueNode
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let overlayNode: ChartFigureNode
    let dateNode: ChartLabelNode
    let yearNode: ChartLabelNode
    let valueNodes: [ChartLabelNode]
    
    private let horGap = CGFloat(7)
    private let verGap = CGFloat(5)
    private let innerGap = CGFloat(15)
    
    var overlayNodeFrame: CGRect {
        let leftLaneHeight = dateNode.sizeThatFits(.zero).height + yearNode.sizeThatFits(.zero).height
        let rightLaneHeight = valuesHeight
        let height = verGap + max(leftLaneHeight, rightLaneHeight) + verGap
        return CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    
    var dateNodeFrame: CGRect {
        let size = dateNode.sizeThatFits(.zero)
        let topY = verGap
        return CGRect(x: horGap, y: topY, width: size.width, height: size.height)
    }

    var yearNodeFrame: CGRect {
        let size = yearNode.sizeThatFits(.zero)
        let topY = dateNodeFrame.maxY
        return CGRect(x: horGap, y: topY, width: size.width, height: size.height)
    }
    
    var valueNodeFrames: [CGRect] {
        var topY = verGap
        return valueNodes.map { node in
            let size = node.sizeThatFits(.zero)
            defer { topY += size.height }
            
            let leftX = bounds.width - horGap - size.width
            return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        }
    }
    
    var totalSize: CGSize {
        return CGSize(
            width: contentWidth,
            height: verGap + max(
                dateNodeFrame.maxY,
                valueNodeFrames.last?.maxY ?? 0
            )
        )
    }
    
    private var valuesNodeSizes: [CGSize] {
        return valueNodes.map { $0.sizeThatFits(.zero) }
    }
    
    private var valuesMaxWidth: CGFloat {
        return valuesNodeSizes.map({ $0.width }).max() ?? 0
    }
    
    private var valuesHeight: CGFloat {
        return valuesNodeSizes.map({ $0.height }).reduce(0, +)
    }
    
    private var contentWidth: CGFloat {
        let dateWidth = dateNode.sizeThatFits(.zero).width
        let yearWidth = yearNode.sizeThatFits(.zero).width
        return horGap + max(dateWidth, yearWidth) + innerGap + valuesMaxWidth + horGap
    }
}
