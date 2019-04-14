//
//  ChartLineGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartLineGraphNode: IChartGraphNode {
}

class ChartLineGraphNode: ChartGraphNode, IChartLineGraphNode {
    private let pointerLineNode = ChartNode()
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat) {
        super.init(chart: chart, config: config, formattingProvider: formattingProvider)
        
        pointerLineNode.isHidden = true
        addSubview(pointerLineNode)
        
        configure(figure: .joinedLines) { _, node, line in
            node.strokeColor = line.color
            node.width = width
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        return false
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   date: Date,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartLinePointsOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: date,
            completion: completion
        )
    }
    
    override func obtainFocusCalculationOperation(meta: ChartSliceMeta,
                                                  context: ChartFocusOperationContext,
                                                  duration: TimeInterval,
                                                  completion: @escaping (CalculateFocusResult) -> Void) -> ChartFocusOperation {
        return ChartLineFocusOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: context,
            completion: completion
        )
    }
    
    override func updateChart(points: [String: [CGPoint]]) {
        for (node, line) in zip(orderedNodes, chart.lines) {
            node.points = points[line.key] ?? []
        }
    }
    
    override func updateFocus(_ focuses: [UIEdgeInsets], edges: [ChartRange], duration: TimeInterval) {
        super.updateFocus(focuses, edges: edges, duration: duration)
        
        zip(orderedNodes, config.lines).forEach { node, lineConfig in
            let targetAlpha = CGFloat(lineConfig.visible ? 1.0 : 0)
            if node.alpha != targetAlpha {
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
        }
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            left: edges.first ?? ChartRange(start: 0, end: 0),
            right: nil,
            duration: duration
        )
    }
    
    override func updatePointer(meta: ChartSliceMeta, totalEdges: [ChartRange]) {
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: chart.lines.map { _ in totalEdges.first ?? ChartRange(start: 0, end: 0) },
            options: [.line, .dots]
        )
    }
}
