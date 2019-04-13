//
//  ChartBarGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 09/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartBarGraphNode: IChartGraphNode {
}

class ChartBarGraphNode: ChartGraphNode, IChartBarGraphNode {
    private let pointerLineNode = ChartNode()
    
    override init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        super.init(chart: chart, config: config, formattingProvider: formattingProvider)
        
        pointerLineNode.isHidden = true
        addSubview(pointerLineNode)
        
        configure(figure: .filledPaths) { index, node, line in
            node.fillColor = line.color
            node.layer.zPosition = -CGFloat(index)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func placeBars(meta: ChartSliceMeta, offset: CGFloat, points: [String: [CGPoint]], duration: TimeInterval) {
        zip(chart.lines, config.lines).forEach { line, lineConfig in
            guard let node = figureNodes[line.key] else { return }
            
            if let point = points[line.key] {
                guard let firstPoint = point.first else { return }
                let restPoints = point.dropFirst()
                
                let path = UIBezierPath()
                path.move(to: firstPoint)
                restPoints.forEach(path.addLine)
                path.close()
                
                node.bezierPaths = [path]
            }
            else {
                node.bezierPaths = []
            }
        }
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   date: Date,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> CalculatePointsOperation {
        return BarCalculateOperation(
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
        abort()
    }
    
    override func updateChart(_ chart: Chart, meta: ChartSliceMeta, edges: [ChartRange], duration: TimeInterval) {
        guard let points = cachedPointsResult?.points else { return }
        
        placeBars(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            points: points,
            duration: duration
        )
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            left: edges.first ?? ChartRange(start: 0, end: 0),
            right: nil,
            duration: duration
        )
    }
    
    override func updatePointer(meta: ChartSliceMeta) {
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: [],
            options: [.line]
        )
    }
}

fileprivate final class BarCalculateOperation: CalculatePointsOperation {
    override func calculateResult() -> CalculatePointsResult {
        let edge = calculateSliceEdge(meta: meta)
        let points = calculateNormalizedPoints(edge: edge, with: meta)
        
        return CalculatePointsResult(
            range: config.range,
            edges: [edge],
            points: points
        )
    }
    
    private func calculateSliceEdge(meta: ChartSliceMeta) -> ChartRange {
        let visibleLineKeys = chart.visibleLines(config: config).map { $0.key }
        
        let sums: [Int] = chart.axis[meta.visibleIndices].map { item in
            let visibleValues = visibleLineKeys.compactMap { item.values[$0] }
            let summarizedValues = visibleValues.reduce(0, +)
            return summarizedValues
        }
        
        return ChartRange(start: 0, end: CGFloat(sums.max() ?? 0))
    }
    
    private func calculateNormalizedPoints(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        let baseX = -(meta.totalWidth * config.range.start)
        let extraHeight = bounds.height * 0.15
        var map = [String: [CGPoint]]()
        var values = [Int](repeating: 0, count: chart.axis.count)
        
        for (line, lineConfig) in zip(chart.lines, config.lines) {
            let oldValues = values
            
            if lineConfig.visible {
                line.values.enumerated().forEach { index, value in values[index] += value }
            }
            
            var currentX = baseX
            var points = [CGPoint]()
            
            for value in values {
                let currentY = bounds.calculateY(value: value, edge: edge)
                
                points.append(CGPoint(x: currentX, y: currentY))
                
                currentX += meta.stepX
                
                points.append(CGPoint(x: currentX, y: currentY))
            }
            
            for (oldValue, value) in zip(oldValues, values).reversed() {
                let currentY: CGFloat
                if lineConfig.visible {
                    currentY = bounds.calculateY(value: oldValue, edge: edge) + extraHeight
                }
                else {
                    currentY = bounds.calculateY(value: value, edge: edge)
                }
                
                points.append(CGPoint(x: currentX, y: currentY))
                
                currentX -= meta.stepX
                
                points.append(CGPoint(x: currentX, y: currentY))
            }
            
            map[line.key] = points
        }
        
        return map
    }
}
