//
//  ChartTimelineControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 16/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartTimelineControl: class {
}

final class ChartTimelineControl: ChartNode, IChartTimelineControl {
    private let chart: Chart
    private let formattingProvider: IFormattingProvider
    
    private var dateNodes = [Int: ChartLabelNode]()
    
    private var config: ChartConfig
    private var overlap = UIEdgeInsets.zero
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = config
        self.formattingProvider = formattingProvider
        
        super.init(frame: .zero)
        
        clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        update()
    }
    
    override func updateDesign() {
        super.updateDesign()
        colorizeDateNodes(Array(dateNodes.values))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeDateNodes(Array(dateNodes.values))
        update()
    }
    
    private func resizeDateNodes(_ nodes: [ChartLabelNode]) {
        let dateWidth = bounds.size.width / 7
        let height = bounds.size.height
        
        dateNodes.values.forEach { node in
            node.transform = .identity
            node.frame = CGRect(x: 0, y: 0, width: dateWidth, height: height)
        }
    }
    
    private func colorizeDateNodes(_ nodes: [ChartLabelNode]) {
        let color = DesignBook.shared.color(.chartIndexForeground)
        
        dateNodes.values.forEach { node in
            node.textColor = color
        }
    }
    
    private func update() {
        guard bounds.width > 0 else { return }
        guard config.range.distance > 0 else { return }

        let meta = chart.obtainMeta(
            config: config,
            bounds: bounds
        )
        
        let axisLength = CGFloat(chart.axis.count)
        let dateWidth = bounds.width / 7
        let totalWidth = bounds.width / config.range.distance
        let rightEdge = bounds.width + (1.0 - config.range.end) * totalWidth
        
        let leftIndex = Int(floor(axisLength * config.range.start))
        let rightIndex = Int(min(axisLength, ceil(axisLength * config.range.end) + (dateWidth / meta.stepX)))
        let innerIndices = (leftIndex ..< rightIndex).reversed()
        
        let skippingStep = calculateStep(dateWidth: dateWidth, rightEdge: rightEdge, meta: meta)
        let skippingSemiStep = max(1, skippingStep / 2)
        
        let fadingStartDistance = dateWidth * 0.05
        let fadingEndDistance = dateWidth * 0.2
        
        for index in (0 ..< leftIndex) {
            let storageIndex = visibleIndexToStorageIndex(index)
            possibleNode(index: storageIndex)?.alpha = 0
        }
        
        for index in (rightIndex ..< chart.axis.count) {
            let storageIndex = visibleIndexToStorageIndex(index)
            possibleNode(index: storageIndex)?.alpha = 0
        }
        
        for (dateIndex, index) in zip(innerIndices, innerIndices.map(visibleIndexToStorageIndex)) {
            if (index % skippingStep) == 0 {
                let node = ensureNode(index: index, date: chart.axis[dateIndex].date, dateWidth: dateWidth)
                node.transform = nodeTransform(rightEdge: rightEdge, dateWidth: dateWidth, meta: meta, index: index)
                node.alpha = 1.0
            }
            else if (index % skippingSemiStep) == 0 {
                let primaryIndex = index - skippingSemiStep
                let primaryLeftAnchor = rightEdge - CGFloat(primaryIndex) * meta.stepX - dateWidth
                let rightAnchor = rightEdge - CGFloat(index) * meta.stepX
                
                if primaryLeftAnchor < rightAnchor {
                    let distance = rightAnchor - primaryLeftAnchor
                    if distance < fadingStartDistance {
                        let node = ensureNode(index: index, date: chart.axis[dateIndex].date, dateWidth: dateWidth)
                        node.transform = nodeTransform(rightEdge: rightEdge, dateWidth: dateWidth, meta: meta, index: index)
                        node.alpha = 1.0
                    }
                    else if distance > fadingEndDistance {
                        possibleNode(index: index)?.alpha = 0
                    }
                    else {
                        let node = ensureNode(index: index, date: chart.axis[dateIndex].date, dateWidth: dateWidth)
                        let coef = distance.percent(from: fadingStartDistance, to: fadingEndDistance)
                        node.transform = nodeTransform(rightEdge: rightEdge, dateWidth: dateWidth, meta: meta, index: index)
                        node.alpha = 1.0 - coef
                    }
                }
                else {
                    let node = ensureNode(index: index, date: chart.axis[dateIndex].date, dateWidth: dateWidth)
                    node.transform = nodeTransform(rightEdge: rightEdge, dateWidth: dateWidth, meta: meta, index: index)
                    node.alpha = 1.0
                }
            }
            else {
                possibleNode(index: index)?.alpha = 0
            }
        }
    }
    
    private func calculateStep(dateWidth: CGFloat, rightEdge: CGFloat, meta: ChartSliceMeta) -> Int {
        let skippingNumber = Int(ceil(dateWidth / meta.stepX))
        return calculateCoveringDuoPower(value: skippingNumber)
    }
    
    private func visibleIndexToStorageIndex(_ index: Int) -> Int {
        return chart.axis.count - index - 1
    }
    
    private func ensureNode(index: Int, date: Date, dateWidth: CGFloat) -> ChartLabelNode {
        if let node = dateNodes[index] {
            return node
        }
        
        let node = ChartLabelNode()
        node.frame = CGRect(x: 0, y: 0, width: dateWidth, height: bounds.height)
        node.text = formattingProvider.format(date: date, style: .shortDate)
        node.textColor = DesignBook.shared.color(.chartIndexForeground)
        node.font = UIFont.systemFont(ofSize: 8)
        node.textAlignment = .right
        
        addSubview(node)
        dateNodes[index] = node
        
        return node
    }
    
    private func possibleNode(index: Int) -> ChartLabelNode? {
        return dateNodes[index]
    }
    
    private func nodeTransform(rightEdge: CGFloat,
                               dateWidth: CGFloat,
                               meta: ChartSliceMeta,
                               index: Int) -> CGAffineTransform {
        let leftX = rightEdge - CGFloat(index) * meta.stepX - dateWidth
        return CGAffineTransform(translationX: leftX, y: 0)
    }
}

private func calculateCoveringDuoPower(value: Int) -> Int {
    for i in (0 ..< 32).indices.reversed() {
        let bit = ((value & (1 << i)) > 0)
        guard bit else { continue }
        
        if value.nonzeroBitCount > 1 {
            return (1 << (i + 1))
        }
        else {
            return (1 << i)
        }
    }
    
    return 1
}
