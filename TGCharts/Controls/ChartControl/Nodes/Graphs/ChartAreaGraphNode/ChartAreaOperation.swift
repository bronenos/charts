//
//  ChartAreaOperation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class ChartAreaPointsOperation: ChartPointsOperation {
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
            }
            
            for (oldValue, value) in zip(oldValues, values).reversed() {
                currentX -= stepX
                
                let currentY: CGFloat
                if lineConfig.visible {
                    currentY = bounds.calculateY(value: oldValue, edge: edge) + extraHeight
                }
                else {
                    currentY = bounds.calculateY(value: value, edge: edge)
                }
                
                points.append(CGPoint(x: currentX, y: currentY))
            }
            
            map[line.key] = points
        }
        
        return map
    }
}

class ChartAreaFocusOperation: ChartFocusOperation {
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
                sliceEdges: [sliceEdge]
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
