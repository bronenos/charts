//
//  ChartAreaOperation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class ChartAreaPointsOperation: ChartBarPointsOperation {
    override func calculateResult() -> CalculatePointsResult {
        let totalEdge = calculateSliceEdge(
            indices: chart.axis.indices
        )
        
        let sliceEdge = calculateSliceEdge(
            indices: meta.visibleIndices
        )
        
        let points = calculatePoints(
            bounds: bounds,
            chart: chart,
            config: config,
            totalEdge: totalEdge,
            meta: meta
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
}

class ChartAreaEyesOperation: ChartBarEyesOperation {
    override func calculateResult() -> CalculateEyesResult {
        let sliceEdge = calculateSliceEdge(
            indices: meta.visibleIndices
        )
        
        let eyes = calculateEyes(
            context: ChartEyeOperationContext(
                totalEdges: context.totalEdges,
                lineEdges: [sliceEdge]
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
                         meta: ChartSliceMeta) -> [String: [CGPoint]] {
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
                let currentY = bounds.calculateY(value: value, edge: totalEdge)
                
                points.append(CGPoint(x: currentX, y: currentY))
                
                currentX += stepX
            }
            
            for (oldValue, value) in zip(oldValues, values).reversed() {
                currentX -= stepX
                
                let currentY: CGFloat
                if lineConfig.visible {
                    currentY = bounds.calculateY(value: oldValue, edge: totalEdge) + extraHeight
                }
                else {
                    currentY = bounds.calculateY(value: value, edge: totalEdge)
                }
                
                points.append(CGPoint(x: currentX, y: currentY))
            }
            
            map[line.key] = points
        }
        
        return map
    }
}
