//
//  ChartLineOperation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class ChartLinePointsOperation: ChartPointsOperation {
    override func calculateResult() -> CalculatePointsResult {
        let totalEdge = calculateLineEdge(
            lines: chart.lines,
            indices: chart.axis.indices
        )
        
        let sliceEdge = calculateLineEdge(
            lines: chart.visibleLines(config: config),
            indices: meta.visibleIndices
        )
        
        let points = calculateNormalizedPoints(
            edge: totalEdge,
            with: meta
        )
        
        let context = ChartFocusOperationContext(
            totalEdges: [totalEdge],
            sliceEdges: [ChartRange](repeating: sliceEdge, count: chart.lines.count)
        )
        
        let focuses = calculateLineFocuses(
            config: config,
            context: context
        )
        
        return CalculatePointsResult(
            range: config.range,
            context: context,
            points: points,
            focuses: focuses
        )
    }
    
    func calculateNormalizedPoints(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGPoint]] {
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

class ChartLineFocusOperation: ChartFocusOperation {
    override func calculateResult() -> CalculateFocusResult {
        let lines = chart.visibleLines(config: config)
        
        let sliceEdge = calculateLineEdge(
            lines: lines,
            indices: meta.visibleIndices
        )
        
        let focuses = calculateLineFocuses(
            config: config,
            context: ChartFocusOperationContext(
                totalEdges: context.totalEdges,
                sliceEdges: [ChartRange](repeating: sliceEdge, count: chart.lines.count)
            )
        )
        
        return CalculateFocusResult(
            context: context,
            edges: [sliceEdge],
            focuses: focuses
        )
    }
}

extension Operation {
    func calculateLineEdge(lines: [ChartLine], indices: Range<Int>) -> ChartRange {
        var lowerValue = Int.max
        var upperValue = Int.min
        
        if let firstValue = lines.first?.values[indices].first {
            lowerValue = firstValue
            upperValue = firstValue
        }
        else {
            return ChartRange(start: 0, end: 0)
        }
        
        indices.forEach { index in
            for value in lines.compactMap({ $0.values[index] }) {
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
    
    func calculateLineFocuses(config: ChartConfig, context: ChartFocusOperationContext) -> [UIEdgeInsets] {
        guard let totalEdge = context.totalEdges.first else {
            return []
        }
        
        let left = config.range.start
        let right = config.range.end

        return context.sliceEdges.map { sliceEdge in
            if sliceEdge.distance > 0 {
                let top = sliceEdge.end.percent(from: totalEdge.start, to: totalEdge.end)
                let bottom = sliceEdge.start.percent(from: totalEdge.start, to: totalEdge.end)
                return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            }
            else {
                return UIEdgeInsets(top: 1.0, left: left, bottom: 0, right: right)
            }
        }
    }
}
