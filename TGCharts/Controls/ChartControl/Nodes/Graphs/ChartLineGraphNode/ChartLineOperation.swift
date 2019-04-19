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
        let totalEdge = calculateEdge(
            lines: chart.lines,
            indices: chart.axis.indices
        )
        
        let sliceEdge = calculateEdge(
            lines: chart.visibleLines(config: config),
            indices: meta.visibleIndices
        )
        
        let points = calculatePoints(
            bounds: bounds,
            chart: chart,
            totalEdge: totalEdge,
            numberOfSteps: context
        )
        
        let context = ChartEyeOperationContext(
            valueEdges: [totalEdge],
            totalEdges: [totalEdge],
            lineEdges: clone(sliceEdge, number: chart.lines.count)
        )
        
        let eyes = calculateEyes(
            config: config,
            context: context,
            sliceEdges: context.lineEdges
        )
        
        return CalculatePointsResult(
            range: config.range,
            context: context,
            points: points,
            eyes: eyes
        )
    }
}

class ChartLineEyesOperation: ChartEyesOperation {
    override func calculateResult() -> CalculateEyesResult {
        let sliceEdges = clone(
            calculateEdge(
                lines: chart.visibleLines(config: config),
                indices: meta.visibleIndices
            ),
            number: chart.lines.count
        )

        let eyes = calculateEyes(
            config: config,
            context: context,
            sliceEdges: sliceEdges
        )
        
        return CalculateEyesResult(
            context: ChartEyeOperationContext(
                valueEdges: context.valueEdges,
                totalEdges: context.totalEdges,
                lineEdges: zip(context.lineEdges, sliceEdges).map { contextualEdge, edge in
                    return (edge.distance > 0 ? edge : contextualEdge)
                }
            ),
            edges: [sliceEdges.first ?? .empty],
            eyes: eyes
        )
    }
}

fileprivate extension Operation {
    func calculatePoints(bounds: CGRect,
                         chart: Chart,
                         totalEdge: ChartRange,
                         numberOfSteps: Int) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        let stepX = bounds.width / CGFloat(numberOfSteps)
        
        var map = [String: [CGPoint]]()
        
        for line in chart.lines {
            var currentX = CGFloat(0)
            map[line.key] = line.values.enumerated().map { index, value in
                defer { currentX += stepX }
                
                let y = bounds.calculateY(value: value, edge: totalEdge)
                return CGPoint(x: currentX, y: y)
            }
        }
        
        return map
    }
    
    func calculateEdge(lines: [ChartLine], indices: Range<Int>) -> ChartRange {
        var lowerValue = Int.max
        var upperValue = Int.min
        
        if let firstValue = lines.first?.values[indices].first {
            lowerValue = firstValue
            upperValue = firstValue
        }
        else {
            return .empty
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
    
    func calculateEyes(config: ChartConfig,
                       context: ChartEyeOperationContext,
                       sliceEdges: [ChartRange]) -> [ChartGraphEye] {
        guard let totalEdge = context.totalEdges.first else { return [] }
        
        let left = config.range.start
        let right = config.range.end
        
        let distanceBase = config.standardDistance
        let distanceFactor = config.range.distance.percent(from: distanceBase, to: distanceBase * 3)
        let scaleFactor = max(0.2, 1.0 - (0.75 * distanceFactor))
        
        return zip(context.lineEdges, sliceEdges).map { contextualSliceEdge, sliceEdge in
            if sliceEdge.distance > 0 {
                let top = sliceEdge.end.percent(inside: totalEdge)
                let bottom = sliceEdge.start.percent(inside: totalEdge)
                let edges = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
                return ChartGraphEye(edges: edges, scaleFactor: scaleFactor)
            }
            else {
                let bottom = contextualSliceEdge.start.percent(inside: totalEdge)
                let edges = UIEdgeInsets(top: bottom + 10.0, left: left, bottom: bottom, right: right)
                return ChartGraphEye(edges: edges, scaleFactor: scaleFactor)
            }
        }
    }
}
