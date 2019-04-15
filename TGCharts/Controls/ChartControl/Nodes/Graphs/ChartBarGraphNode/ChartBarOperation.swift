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
            chart: chart,
            config: config,
            indices: chart.axis.indices
        )
        
        let sliceEdge = calculateSliceEdge(
            chart: chart,
            config: config,
            indices: meta.visibleIndices
        )

        let points = calculatePoints(
            bounds: bounds,
            chart: chart,
            config: config,
            totalEdge: totalEdge,
            meta: meta,
            numberOfSteps: context
        )
        
        let context = ChartEyeOperationContext(
            valueEdges: [totalEdge],
            totalEdges: [totalEdge],
            lineEdges: [sliceEdge]
        )
        
        let eyes = calculateEyes(
            config: config,
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
}

class ChartBarEyesOperation: ChartEyesOperation {
    override func calculateResult() -> CalculateEyesResult {
        let sliceEdge = calculateSliceEdge(
            chart: chart,
            config: config,
            indices: meta.visibleIndices
        )
        
        let eyes = calculateEyes(
            config: config,
            context: ChartEyeOperationContext(
                valueEdges: context.valueEdges,
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
}

fileprivate extension Operation {
    func calculatePoints(bounds: CGRect,
                         chart: Chart,
                         config: ChartConfig,
                         totalEdge: ChartRange,
                         meta: ChartSliceMeta,
                         numberOfSteps: Int) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        let stepX = bounds.width / CGFloat(numberOfSteps)
        let extraHeight = bounds.height * 0.15
        
        var map = [String: [CGPoint]]()
        var values = clone(0, number: numberOfSteps)
        
        for (line, lineConfig) in zip(chart.lines, config.lines) {
            let oldValues = values
            
            if lineConfig.visible {
                line.values.enumerated().forEach { index, value in values[index] += value }
            }
            
            var currentX = CGFloat(0)
            var points = [CGPoint]()
            
            for value in values {
                let currentY = bounds.calculateY(value: value, edge: totalEdge)
                
                points.append(CGPoint(x: currentX, y: currentY))
                
                currentX += stepX
                
                points.append(CGPoint(x: currentX, y: currentY))
            }
            
            for (oldValue, value) in zip(oldValues, values).reversed() {
                let currentY: CGFloat
                if lineConfig.visible {
                    currentY = bounds.calculateY(value: oldValue, edge: totalEdge) + extraHeight
                }
                else {
                    currentY = bounds.calculateY(value: value, edge: totalEdge)
                }
                
                points.append(CGPoint(x: currentX, y: currentY))
                
                currentX -= stepX
                
                points.append(CGPoint(x: currentX, y: currentY))
            }
            
            map[line.key] = points
        }
        
        return map
    }
    
    func calculateSliceEdge(chart: Chart, config: ChartConfig, indices: Range<Int>) -> ChartRange {
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
    
    func calculateEyes(config: ChartConfig, context: ChartEyeOperationContext, sliceEdge: ChartRange) -> [ChartGraphEye] {
        guard let totalEdge = context.totalEdges.first else {
            return []
        }
        
        return config.lines.map { _ in
            let left = config.range.start
            let right = config.range.end
            
            if sliceEdge.distance > 0, totalEdge.distance > 0 {
                let top = sliceEdge.end / totalEdge.end
                let edges = UIEdgeInsets(top: top, left: left, bottom: 0, right: right)
                return ChartGraphEye(edges: edges, scaleFactor: 1.0)
            }
            else {
                let edges = UIEdgeInsets(top: 10.0, left: left, bottom: 0, right: right)
                return ChartGraphEye(edges: edges, scaleFactor: 1.0)
            }
        }
    }
}
