//
//  ChartBarOperation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class ChartBarPointsOperation: ChartPointsOperation {
    override func calculateResult() -> CalculatePointsResult {
        let sliceEdge = calculateStackedSliceEdge(
            chart: chart,
            config: config,
            indices: meta.visibleIndices
        )

        let totalEdge = calculateStackedSliceEdge(
            chart: chart,
            config: config,
            indices: chart.axis.indices
        )

        let points = calculateNormalizedPoints(
            edge: totalEdge,
            with: meta
        )
        
        let context = ChartFocusOperationContext(
            totalEdges: [totalEdge],
            sliceEdges: [sliceEdge]
        )
        
        let focuses = calculateStackedFocuses(
            config: config,
            context: context,
            sliceEdge: sliceEdge
        )
        
        return CalculatePointsResult(
            range: config.range,
            context: context,
            points: points,
            focuses: focuses
        )
    }
    
    private func calculateNormalizedPoints(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        let stepX = bounds.width / CGFloat(chart.axis.count)
        let extraHeight = bounds.height * 0.15
        
        var map = [String: [CGPoint]]()
        var values = [Int](repeating: 0, count: chart.axis.count)
        
        for (line, lineConfig) in zip(chart.lines, config.lines) {
            let oldValues = values
            
            if lineConfig.visible {
                line.values.enumerated().forEach { index, value in values[index] += value }
            }
            
            var currentX = CGFloat(0)
            var points = [CGPoint]()
            
            for value in values {
                let currentY = bounds.calculateY(value: value, edge: edge)
                
                points.append(CGPoint(x: currentX, y: currentY))
                
                currentX += stepX
                
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
                
                currentX -= stepX
                
                points.append(CGPoint(x: currentX, y: currentY))
            }
            
            map[line.key] = points
        }
        
        return map
    }
}

class ChartBarFocusOperation: ChartFocusOperation {
    override func calculateResult() -> CalculateFocusResult {
        let sliceEdge = calculateStackedSliceEdge(
            chart: chart,
            config: config,
            indices: meta.visibleIndices
        )
        
        let currentEdge = calculateStackedSliceEdge(
            chart: chart,
            config: config,
            indices: chart.axis.indices
        )
        
        let focuses = calculateStackedFocuses(
            config: config,
            context: ChartFocusOperationContext(
                totalEdges: context.totalEdges,
                sliceEdges: [ChartRange](repeating: sliceEdge, count: chart.lines.count)
            ),
            sliceEdge: sliceEdge
        )
        
        return CalculateFocusResult(
            context: context,
            edges: [currentEdge],
            focuses: focuses
        )
    }
}

extension Operation {
    func calculateStackedSliceEdge(chart: Chart, config: ChartConfig, indices: Range<Int>) -> ChartRange {
        var currentGrowingValues = [Int](repeating: 0, count: indices.count)
        var lineMaximalValues = [Int](repeating: 0, count: chart.lines.count)
        
        for (lineIndex, line) in chart.lines.enumerated() {
            if config.lines[lineIndex].visible {
                for (valueIndex, value) in line.values[indices].enumerated() {
                    currentGrowingValues[valueIndex] += value
                }
            }
            
            lineMaximalValues[lineIndex] = currentGrowingValues.max() ?? 0
        }
        
        let edges = lineMaximalValues.map { value in
            return ChartRange(start: 0, end: CGFloat(value))
        }
        
        let maximalValue = edges.map({ $0.end }).max() ?? 0
        return ChartRange(start: 0, end: maximalValue)
    }
    
    func calculateStackedFocuses(config: ChartConfig, context: ChartFocusOperationContext, sliceEdge: ChartRange) -> [UIEdgeInsets] {
        guard let totalEdge = context.totalEdges.first else {
            return []
        }
        
        return config.lines.map { _ in
            let left = config.range.start
            let right = config.range.end
            
            if totalEdge.distance > 0 {
                let top = sliceEdge.end / totalEdge.end
                return UIEdgeInsets(top: top, left: left, bottom: 0, right: right)
            }
            else {
                return UIEdgeInsets(top: 1.0, left: left, bottom: 0, right: right)
            }
        }
    }
}
