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
    
    internal func placeLines(meta: ChartSliceMeta,
                             offset: CGFloat,
                             points: [String: [CGPoint]],
                             duration: TimeInterval) {
        zip(chart.lines, config.lines).forEach { line, lineConfig in
            figureNodes[line.key]?.points = points[line.key] ?? []
        }
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   date: Date,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> CalculatePointsOperation {
        return LineCalculatePointsOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            source: date,
            completion: completion
        )
    }
    
    override func obtainFocusCalculationOperation(meta: ChartSliceMeta,
                                                  edges: [ChartRange],
                                                  duration: TimeInterval,
                                                  completion: @escaping (CalculateFocusResult) -> Void) -> CalculateFocusOperation {
        return LineCalculateFocusOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            source: edges,
            completion: completion
        )
    }
    
    override func updateChart(_ chart: Chart, meta: ChartSliceMeta, edges: [ChartRange], duration: TimeInterval) {
        placeLines(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            points: cachedPointsResult?.points ?? [:],
            duration: duration
        )
    }
    
    override func updateFocus(_ focus: UIEdgeInsets, edges: [ChartRange], duration: TimeInterval) {
        figureNodes.values.forEach { node in
            node.updateFocus(focus, duration: duration)
        }
        
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
    
    override func updatePointer(meta: ChartSliceMeta) {
        guard let edge = cachedPointsResult?.edges.first else { return }
        
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: chart.lines.map { _ in edge },
            options: [.line, .dots]
        )
    }
}

fileprivate final class LineCalculatePointsOperation: CalculatePointsOperation {
    override func calculateResult() -> CalculatePointsResult {
        let edge = calculateTotalEdge(meta: meta)
        let points = calculateNormalizedPoints(edge: edge, with: meta)
        
        return CalculatePointsResult(
            range: config.range,
            edges: [edge],
            points: points
        )
    }
    
    private func calculateTotalEdge(meta: ChartSliceMeta) -> ChartRange {
        let visibleLines = chart.visibleLines(config: config)
        var lowerValue = Int.max
        var upperValue = Int.min
        
        if let firstValue = visibleLines.first?.values.first {
            lowerValue = firstValue
            upperValue = firstValue
        }
        else {
            return ChartRange(start: 0, end: 0)
        }

        chart.axis.indices.forEach { index in
            for value in visibleLines.compactMap({ $0.values[index] }) {
                if value > upperValue {
                    upperValue = value
                }
                else if value < lowerValue {
                    lowerValue = value
                }
            }
        }
        
        return ChartRange(
            start: CGFloat(lowerValue),
            end: CGFloat(upperValue)
        )
    }
    
    private func calculateNormalizedPoints(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        let stepX = bounds.width / CGFloat(chart.axis.count - 1)
        
        var map = [String: [CGPoint]]()
        
        for line in chart.lines {
            var currentX = CGFloat(0)
            map[line.key] = line.values.enumerated().map { index, value in
                defer { currentX += stepX }
                
                let y = bounds.calculateY(value: value, edge: edge)
                return CGPoint(x: currentX, y: y)
            }
        }
        
        return map
    }
}

fileprivate final class LineCalculateFocusOperation: CalculateFocusOperation {
    override func calculateResult() -> CalculateFocusResult {
        let edge = calculateSliceEdge(meta: meta)
        let focus = calculateFocus(edge: edge)
        
        return CalculateFocusResult(
            edges: [edge],
            focus: focus
        )
    }
    
    private func calculateSliceEdge(meta: ChartSliceMeta) -> ChartRange {
        let visibleLines = chart.visibleLines(config: config)
        var lowerValue = Int.max
        var upperValue = Int.min
        
        if let firstValue = visibleLines.first?.values[meta.visibleIndices].first {
            lowerValue = firstValue
            upperValue = firstValue
        }
        else {
            return ChartRange(start: 0, end: 0)
        }
        
        meta.visibleIndices.forEach { index in
            for value in visibleLines.compactMap({ $0.values[index] }) {
                if value > upperValue {
                    upperValue = value
                }
                else if value < lowerValue {
                    lowerValue = value
                }
            }
        }
        
        return ChartRange(
            start: CGFloat(lowerValue),
            end: CGFloat(upperValue)
        )
    }
    
    private func calculateFocus(edge: ChartRange) -> UIEdgeInsets {
        guard let sourceEdge = source.first else {
            return .zero
        }
        
        let top = edge.end.percent(from: sourceEdge.start, to: sourceEdge.end)
        let left = config.range.start
        let bottom = edge.start.percent(from: sourceEdge.start, to: sourceEdge.end)
        let right = config.range.end
        
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}
