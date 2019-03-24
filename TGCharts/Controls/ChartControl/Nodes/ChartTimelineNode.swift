//
//  ChartTimelineNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 16/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartTimelineNode: IChartSlicableNode {
}

final class ChartTimelineNode: ChartNode, IChartTimelineNode {
    private let formattingProvider: IFormattingProvider
    
    private var dateNodes = [Date: IChartLabelNode]()
    
    private var chart = Chart()
    private var config = ChartConfig()
    private var overlap = UIEdgeInsets.zero
    
    init(tag: String?, formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        super.init(tag: tag ?? "[timeline]", cachable: false)
    }
    
    override var frame: CGRect {
        didSet { update() }
    }
    
    func setChart(_ chart: Chart, config: ChartConfig, overlap: UIEdgeInsets, duration: TimeInterval) {
        self.chart = chart
        self.config = config
        self.overlap = overlap
        update()
    }
    
    private func update() {
        guard let meta = obtainMeta(chart: chart, config: config, overlap: overlap) else {
            dateNodes.values.forEach { $0.removeFromParent() }
            dateNodes.removeAll()
            return
        }
        
        guard let firstRenderedIndex = meta.renderedIndices.first else {
            dateNodes.values.forEach { $0.removeFromParent() }
            dateNodes.removeAll()
            return
        }
        
        let dateWidth = size.width / 7
        let additionalNumberOfIndices = 0 // min(firstRenderedIndex, Int(ceil(dateWidth / meta.stepX)))
        let firstEnumeratedIndex = firstRenderedIndex - additionalNumberOfIndices
        
        let axialSlice = chart.axis[firstEnumeratedIndex...].enumerated().reversed()
        let preAxialSlice = chart.axis[0 ..< firstEnumeratedIndex]

        let lastAxialIndex = axialSlice.count - 1
        guard lastAxialIndex >= 0 else { return }

        axialSlice.forEach { index, item in
            let rect = CGRect(
                x: -meta.margins.left + meta.stepX * CGFloat(index - additionalNumberOfIndices) - dateWidth,
                y: 0,
                width: dateWidth,
                height: size.height
            )
            
            if dateNodes[item.date] == nil {
                let dateNode = ChartLabelNode(tag: "date", cachable: true)
                dateNodes[item.date] = dateNode
                
                dateNode.content = ChartLabelNodeContent(
                    text: formattingProvider.format(date: item.date, style: .shortDate),
                    color: DesignBook.shared.color(.chartIndexForeground),
                    font: UIFont.systemFont(ofSize: 8),
                    alignment: .right,
                    limitedToBounds: false
                )
                
                addChild(node: dateNode)
            }
            
            dateNodes[item.date]?.frame = rect
        }
        
        preAxialSlice.forEach { item in
            dateNodes[item.date]?.alpha = 0
        }
        
        let nodes = axialSlice.map({ $0.element.date }).sorted(by: >).compactMap({ dateNodes[$0] })
        let skippingStep = calculateSkippingStep(nodes: nodes)
        performLayout(nodes: nodes, skippingStep: skippingStep)
    }
    
    private func calculateSkippingStep(nodes: [IChartNode]) -> Int {
        guard let primaryAnchor = nodes.first?.frame.minX else {
            return 1
        }
        
        for (index, node) in nodes.enumerated() {
            guard node.frame.maxX <= primaryAnchor else { continue }
            return calculateCoveringDuoPower(value: index)
        }
        
        return 1
    }
    
    private func performLayout(nodes: [IChartNode], skippingStep: Int) {
        let skippingSemiStep = max(1, skippingStep / 2)
        var lastAnchor = CGFloat(0)
        
        for (index, node) in nodes.enumerated() {
            if node.frame.minX < 0, index == nodes.count - 1 {
                node.alpha = 0
            }
            else if (index % skippingStep) == 0 {
                node.alpha = 1.0
                lastAnchor = node.frame.minX
            }
            else if (index % skippingSemiStep) == 0 {
                let distance = node.frame.maxX - lastAnchor
                let limit = node.size.width * 0.25
                let value = 1.0 - min(1.0, distance / limit)
                node.alpha = value
            }
            else {
                node.alpha = 0
            }
        }
    }
}
