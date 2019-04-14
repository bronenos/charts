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
        let totalEdge = calculateSliceEdge(
            indices: chart.axis.indices
        )
        
        let sliceEdge = calculateSliceEdge(
            indices: meta.visibleIndices
        )

        let points = calculateNormalizedPoints(
            edge: totalEdge,
            with: meta
        )
        
        let context = ChartEyeOperationContext(
            totalEdges: [totalEdge],
            lineEdges: [sliceEdge]
        )
        
        let eyes = calculateEyes(
            context: context,
            sliceEdge: sliceEdge
        )
        
        return CalculatePointsResult(
            range: config.range,
            context: context,
            points: points,
            eyes: eyes
        )
    }
    
    private func calculateNormalizedPoints(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        let stepX = bounds.width / CGFloat(chart.axis.count)
        let extraHeight = bounds.height * 0.15
        
        var map = [String: [CGPoint]]()
        var values = clone(0, number: chart.axis.count)
        
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
    
    func calculateSliceEdge(indices: Range<Int>) -> ChartRange {
        return _calculateSliceEdge(chart: chart, config: config, indices: indices)
    }
    
    func calculateEyes(context: ChartEyeOperationContext, sliceEdge: ChartRange) -> [UIEdgeInsets] {
        return _calculateEyes(config: config, context: context, sliceEdge: sliceEdge)
    }
}

class ChartBarEyesOperation: ChartEyesOperation {
    override func calculateResult() -> CalculateEyesResult {
        let sliceEdge = calculateSliceEdge(
            indices: meta.visibleIndices
        )
        
        let eyes = calculateEyes(
            context: ChartEyeOperationContext(
                totalEdges: context.totalEdges,
                lineEdges: clone(sliceEdge, number: chart.lines.count)
            ),
            sliceEdge: sliceEdge
        )
        
        return CalculateEyesResult(
            context: context,
            edges: context.totalEdges,
            eyes: eyes
        )
    }
    
    func calculateSliceEdge(indices: Range<Int>) -> ChartRange {
        return _calculateSliceEdge(chart: chart, config: config, indices: indices)
    }
    
    func calculateEyes(context: ChartEyeOperationContext, sliceEdge: ChartRange) -> [UIEdgeInsets] {
        return _calculateEyes(config: config, context: context, sliceEdge: sliceEdge)
    }
}

fileprivate extension Operation {
    func _calculateSliceEdge(chart: Chart, config: ChartConfig, indices: Range<Int>) -> ChartRange {
        var currentGrowingValues = clone(0, number: indices.count)
        var lineMaximalValues = clone(0, number: chart.lines.count)
        
        for (lineIndex, line) in chart.lines.enumerated() {
            if config.lines[lineIndex].visible {
                for (valueIndex, value) in line.values[indices].enumerated() {
                    currentGrowingValues[valueIndex] += value
                }
            }
            
            lineMaximalValues[lineIndex] = currentGrowingValues.max() ?? 0
        }
        
        let maximalValue = lineMaximalValues.max() ?? 0
        return ChartRange(start: 0, end: CGFloat(maximalValue))
    }
    
    func _calculateEyes(config: ChartConfig, context: ChartEyeOperationContext, sliceEdge: ChartRange) -> [UIEdgeInsets] {
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
                return UIEdgeInsets(top: 10.0, left: left, bottom: 0, right: right)
            }
        }
    }
}
