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
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat, enableControls: Bool) {
        super.init(
            chart: chart,
            config: config,
            formattingProvider: formattingProvider,
            enableControls: enableControls
        )
        
        configure(figure: .joinedLines) { _, node, line in
            node.strokeColor = line.color
            node.strokeWidth = width
            node.minimalScaledWidth = 0.75
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var numberOfSteps: Int {
        return chart.axis.count - 1
    }
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        return false
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartLinePointsOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: numberOfSteps,
            completion: completion
        )
    }
    
    override func obtainEyesCalculationOperation(meta: ChartSliceMeta,
                                                  context: ChartEyeOperationContext,
                                                  duration: TimeInterval,
                                                  completion: @escaping (CalculateEyesResult) -> Void) -> ChartEyesOperation {
        return ChartLineEyesOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: context,
            completion: completion
        )
    }
    
    override func updateChart(points: [String: [CGPoint]]) {
        super.updateChart(points: points)
        
        for (node, line) in zip(orderedNodes, chart.lines) {
            node.points = points[line.key] ?? []
        }
    }
    
    override func updateEyes(_ eyes: [ChartGraphEye], edges: [ChartRange], duration: TimeInterval) {
        super.updateEyes(eyes, edges: edges, duration: duration)
        
        zip(orderedNodes, config.lines).forEach { node, lineConfig in
            let targetAlpha = CGFloat(lineConfig.visible ? 1.0 : 0)
            if node.alpha != targetAlpha {
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
        }
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            left: edges.first ?? .empty,
            right: nil,
            duration: duration
        )
    }
    
    override func updatePointer(eyes: [ChartGraphEye],
                                totalEdges: [ChartRange],
                                duration: TimeInterval) {
        container?.adjustPointer(
            chart: chart,
            config: config,
            eyes: eyes,
            options: [.line, .dots],
            rounder: round,
            duration: duration
        )
    }
    
    override func calculatePoints(forIndex index: Int) -> [CGPoint] {
        return zip(chart.lines, orderedNodes).map { line, node in
            let originalPoint = cachedPoints[line.key]?[index] ?? .zero
            return node.convertOriginalToEffective(point: originalPoint)
        }
    }
}
