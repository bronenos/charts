//
//  ChartDuoOperation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

final class ChartDuoPointsOperation: ChartLinePointsOperation {
    override func calculateResult() -> CalculatePointsResult {
        let totalEdges = calculateEdges(
            lines: chart.lines,
            indices: chart.axis.indices
        )
        
        let sliceEdges = calculateEdges(
            lines: chart.lines,
            config: config,
            indices: meta.visibleIndices
        )
        
        let points = calculatePoints(
            bounds: bounds,
            chart: chart,
            totalEdges: totalEdges,
            meta: meta,
            numberOfSteps: context
        )
        
        let context = ChartEyeOperationContext(
            valueEdges: totalEdges,
            totalEdges: totalEdges,
            lineEdges: sliceEdges
        )
        
        let eyes = calculateEyes(
            config: config,
            context: context,
            sliceEdges: sliceEdges
        )
        
        return CalculatePointsResult(
            range: config.range,
            context: context,
            points: points,
            eyes: eyes
        )
    }
}

final class ChartDuoEyesOperation: ChartLineEyesOperation {
    override func calculateResult() -> CalculateEyesResult {
        let sliceEdges = calculateEdges(
            lines: chart.lines,
            config: config,
            indices: meta.visibleIndices
        )
        
        let eyes = calculateEyes(
            config: config,
            context: self.context,
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
            edges: sliceEdges,
            eyes: eyes
        )
    }
}

fileprivate extension Operation {
    func calculatePoints(bounds: CGRect,
                         chart: Chart,
                         totalEdges: [ChartRange],
                         meta: ChartSliceMeta,
                         numberOfSteps: Int) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        var map = [String: [CGPoint]]()
        let stepX = bounds.width / CGFloat(numberOfSteps)
        
        zip(chart.lines, totalEdges).forEach { line, edge in
            var currentX = CGFloat(0)
            map[line.key] = line.values.enumerated().map { index, value in
                defer { currentX += stepX }
                
                let y = bounds.calculateY(value: value, edge: edge)
                return CGPoint(x: currentX, y: y)
            }
        }
        
        return map
    }
    
    func calculateEdges(lines: [ChartLine], indices: Range<Int>) -> [ChartRange] {
        return lines.map { line in
            let values = Array(line.values[indices])
            
            if let limits = calculateLimits(values) {
                let start = CGFloat(limits.lower)
                let end = CGFloat(limits.upper)
                return ChartRange(start: start, end: end)
            }
            else {
                return .empty
            }
        }
    }
    
    func calculateEdges(lines: [ChartLine], config: ChartConfig, indices: Range<Int>) -> [ChartRange] {
        return zip(lines, config.lines).map { line, lineConfig in
            guard lineConfig.visible else {
                return .empty
            }
            
            let values = Array(line.values[indices])
            guard let limits = calculateLimits(values) else {
                return .empty
            }
            
            let start = CGFloat(limits.lower)
            let end = CGFloat(limits.upper)
            return ChartRange(start: start, end: end)
        }
    }
    
    func calculateEyes(config: ChartConfig, context: ChartEyeOperationContext, sliceEdges: [ChartRange]) -> [ChartGraphEye] {
        let allHidden = sliceEdges.allSatisfy { $0.distance == 0 }
        
        return config.lines.indices.map { index in
            let totalEdge = context.totalEdges[index]
            let contextualSliceEdge = context.lineEdges[index]
            let sliceEdge = sliceEdges[index]
            
            let left = config.range.start
            let right = config.range.end
            
            if sliceEdge.distance > 0 {
                let top = sliceEdge.end.percent(inside: totalEdge)
                let bottom = sliceEdge.start.percent(inside: totalEdge)
                let edges = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
                let scaleFactor = (config.standardDistance / config.range.distance)
                return ChartGraphEye(edges: edges, scaleFactor: scaleFactor)
            }
            else if allHidden {
                let bottom = contextualSliceEdge.start.percent(inside: totalEdge)
                let edges = UIEdgeInsets(top: bottom + 10.0, left: left, bottom: bottom, right: right)
                let scaleFactor = (config.standardDistance / config.range.distance)
                return ChartGraphEye(edges: edges, scaleFactor: scaleFactor)
            }
            else {
                let top = contextualSliceEdge.end.percent(inside: totalEdge)
                let bottom = contextualSliceEdge.start.percent(inside: totalEdge)
                
                if top > bottom {
                    let edges = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
                    let scaleFactor = (config.standardDistance / config.range.distance)
                    return ChartGraphEye(edges: edges, scaleFactor: scaleFactor)
                }
                else {
                    let edges = UIEdgeInsets(top: bottom + 1.0, left: left, bottom: bottom, right: right)
                    let scaleFactor = (config.standardDistance / config.range.distance)
                    return ChartGraphEye(edges: edges, scaleFactor: scaleFactor)
                }
            }
        }
    }
}
