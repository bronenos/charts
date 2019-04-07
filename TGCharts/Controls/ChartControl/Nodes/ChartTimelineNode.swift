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
    private let chart: Chart
    private let formattingProvider: IFormattingProvider
    
    private var dateNodes = [Date: ChartLabelNode]()
    
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
    
    override var frame: CGRect {
        didSet { update() }
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        update()
    }
    
    override func updateDesign() {
        dateNodes.values.forEach { $0.removeFromSuperview() }
        dateNodes.removeAll()
    }
    
    private func update() {
        guard let meta = obtainMeta(chart: chart, config: config) else {
            return
        }

//        guard let firstRenderedIndex = meta.renderedIndices.first else {
//            return
//        }

        let dateWidth = bounds.size.width / 7
//        let additionalNumberOfIndices = 0 // min(firstRenderedIndex, Int(ceil(dateWidth / meta.stepX)))
//        let firstEnumeratedIndex = firstRenderedIndex - additionalNumberOfIndices
//
//        let axialSlice = chart.axis[firstEnumeratedIndex...].enumerated().reversed()
//        let preAxialSlice = chart.axis[0 ..< firstEnumeratedIndex]
//
//        let lastAxialIndex = axialSlice.count - 1
//        guard lastAxialIndex >= 0 else { return }
        
        let totalWidth = bounds.width / config.range.distance
        let rightEdge = bounds.width + (1.0 - config.range.end) * totalWidth

        /*axialSlice*/ chart.axis.reversed().enumerated().forEach { index, item in
            let rect = CGRect(
                x: rightEdge - CGFloat(index) * meta.stepX - dateWidth,
                y: 0,
                width: dateWidth,
                height: bounds.size.height
            )

            if dateNodes[item.date] == nil {
                let dateNode = ChartLabelNode()
                dateNodes[item.date] = dateNode

                dateNode.content = ChartLabelNodeContent(
                    text: formattingProvider.format(date: item.date, style: .shortDate),
                    color: DesignBook.shared.color(.chartIndexForeground),
                    font: UIFont.systemFont(ofSize: 8),
                    alignment: .right,
                    limitedToBounds: false
                )

                addSubview(dateNode)
            }

            dateNodes[item.date]?.frame = rect
        }

//        preAxialSlice.forEach { item in
//            dateNodes[item.date]?.alpha = 0
//        }

        let nodes = chart.axis.map({ $0.date }).sorted(by: >).compactMap({ dateNodes[$0] })
        let skippingStep = calculateSkippingStep(nodes: nodes)
        performLayout(nodes: nodes, skippingStep: skippingStep)
    }
    
    private func calculateSkippingStep(nodes: [ChartLabelNode]) -> Int {
        guard let primaryAnchor = nodes.first?.frame.minX else {
            return 1
        }

        for (index, node) in nodes.enumerated() {
            guard node.frame.maxX <= primaryAnchor else { continue }
            return calculateCoveringDuoPower(value: index)
        }
        
        return 1
    }
    
    private func performLayout(nodes: [ChartLabelNode], skippingStep: Int) {
        let skippingSemiStep = max(1, skippingStep / 2)
        var lastAnchor = CGFloat(0)
        
        for (index, node) in nodes.enumerated() {
            if (index % skippingStep) == 0 {
                node.alpha = 1.0
                lastAnchor = node.frame.minX
            }
            else if (index % skippingSemiStep) == 0 {
                let distance = node.frame.maxX - lastAnchor
                let limit = node.frame.size.width * 0.25
                let value = 1.0 - min(1.0, distance / limit)
                node.alpha = value
            }
            else {
                node.alpha = 0
            }
        }
    }
}
