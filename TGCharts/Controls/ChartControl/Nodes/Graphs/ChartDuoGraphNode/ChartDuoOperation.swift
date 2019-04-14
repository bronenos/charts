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
        let totalEdges = calculateDuoEdge(
            lines: chart.lines,
            indices: chart.axis.indices
        )
        
        let sliceEdges = calculateSliceEdges(
            lines: chart.lines,
            config: config,
            indices: meta.visibleIndices
        )
        
        let points = calculateNormalizedPoints(
            edges: totalEdges,
            with: meta
        )
        
        let context = ChartFocusOperationContext(
            totalEdges: totalEdges,
            sliceEdges: sliceEdges
        )
        
        let focuses = calculateDuoFocuses(
            config: config,
            context: context,
            sliceEdges: sliceEdges
        )
        
        return CalculatePointsResult(
            range: config.range,
            context: context,
            points: points,
            focuses: focuses
        )
    }
    
    private func calculateNormalizedPoints(edges: [ChartRange], with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        var map = [String: [CGPoint]]()
        let stepX = bounds.width / CGFloat(chart.axis.count - 1)
        
        zip(chart.lines, edges).forEach { line, edge in
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

final class ChartDuoFocusOperation: ChartLineFocusOperation {
    override func calculateResult() -> CalculateFocusResult {
        let sliceEdges = calculateSliceEdges(
            lines: chart.lines,
            config: config,
            indices: meta.visibleIndices
        )
        
        let edgess = sliceEdges
        
        let context = ChartFocusOperationContext(
            totalEdges: self.context.totalEdges,
            sliceEdges: zip(self.context.sliceEdges, edgess).map { contextualEdge, edge in
                if edge.distance > 0 {
                    return edge
                }
                else {
                    return contextualEdge
                }
            }
        )
        
        let focuses = calculateDuoFocuses(
            config: config,
            context: self.context,
            sliceEdges: sliceEdges
        )

        return CalculateFocusResult(
            context: context,
            edges: sliceEdges,
            focuses: focuses
        )
    }
}

fileprivate extension Operation {
    func calculateDuoEdge(lines: [ChartLine], indices: Range<Int>) -> [ChartRange] {
        return lines.map { line in
            var lowerValue = Int.max
            var upperValue = Int.min
            
            if let firstValue = line.values[indices].first {
                lowerValue = firstValue
                upperValue = firstValue
            }
            else {
                return ChartRange(start: 0, end: 0)
            }
            
            indices.forEach { index in
                let value = line.values[index]
                
                if value > upperValue {
                    upperValue = value
                }
                else if value < lowerValue {
                    lowerValue = value
                }
            }
            
            return ChartRange(
                start: CGFloat(lowerValue),
                end: CGFloat(upperValue)
            )
        }
    }
    
    func calculateSliceEdges(lines: [ChartLine], config: ChartConfig, indices: Range<Int>) -> [ChartRange] {
        return zip(lines, config.lines).map { line, lineConfig in
            if lineConfig.visible {
                let values = line.values[indices]
                let lowerValue = CGFloat(values.min() ?? 0)
                let upperValue = CGFloat(values.max() ?? 0)
                let range = ChartRange(start: lowerValue, end: upperValue)
                return range
            }
            else {
                return ChartRange(start: 0, end: 0)
            }
        }
    }
    
    func calculateDuoFocuses(config: ChartConfig, context: ChartFocusOperationContext, sliceEdges: [ChartRange]) -> [UIEdgeInsets] {
        let allHidden = sliceEdges.allSatisfy { $0.distance == 0 }
        
        return config.lines.indices.map { index in
            let totalEdge = context.totalEdges[index]
            let contextualSliceEdge = context.sliceEdges[index]
            let sliceEdge = sliceEdges[index]
            
            let left = config.range.start
            let right = config.range.end
            
            if sliceEdge.distance > 0 {
                let top = sliceEdge.end.percent(from: totalEdge.start, to: totalEdge.end)
                let bottom = sliceEdge.start.percent(from: totalEdge.start, to: totalEdge.end)
                return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            }
            else if allHidden {
                let bottom = contextualSliceEdge.start.percent(from: totalEdge.start, to: totalEdge.end)
                return UIEdgeInsets(top: bottom + 10.0, left: left, bottom: bottom, right: right)
            }
            else {
                let top = contextualSliceEdge.end.percent(from: totalEdge.start, to: totalEdge.end)
                let bottom = contextualSliceEdge.start.percent(from: totalEdge.start, to: totalEdge.end)
                return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
            }
        }
    }
}
