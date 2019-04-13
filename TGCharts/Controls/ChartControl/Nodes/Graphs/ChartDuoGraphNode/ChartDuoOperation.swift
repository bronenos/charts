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
            chart: chart,
            config: config,
            meta: meta
        )
        
        let points = calculateNormalizedPoints(
            edges: totalEdges,
            with: meta
        )
        
        let focuses = calculateLineFocuses(
            config: config,
            totalEdge: totalEdges,
            sliceEdges: sliceEdges
        )
        
        return CalculatePointsResult(
            range: config.range,
            edges: totalEdges,
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
            chart: chart,
            config: config,
            meta: meta
        )
        
        let focuses = calculateDuoFocuses(
            config: config,
            totalEdges: source,
            sliceEdges: sliceEdges
        )

        return CalculateFocusResult(
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
            
            print("duo-total line[\(line.key)] range[\(lowerValue)-\(upperValue)]")
            
            return ChartRange(
                start: CGFloat(lowerValue),
                end: CGFloat(upperValue)
            )
        }
    }
    
    func calculateSliceEdges(chart: Chart, config: ChartConfig, meta: ChartSliceMeta) -> [ChartRange] {
        return chart.lines.map { line in
            let values = line.values[meta.visibleIndices]
            let lowerValue = CGFloat(values.min() ?? 0)
            let upperValue = CGFloat(values.max() ?? 0)
            let range = ChartRange(start: lowerValue, end: upperValue)
            return range
        }
    }
    
    func calculateDuoFocuses(config: ChartConfig, totalEdges: [ChartRange], sliceEdges: [ChartRange]) -> [UIEdgeInsets] {
        return zip(totalEdges, sliceEdges).map { totalEdge, sliceEdge in
            let top = sliceEdge.end.percent(from: totalEdge.start, to: totalEdge.end)
            let left = config.range.start
            let bottom = sliceEdge.start.percent(from: totalEdge.start, to: totalEdge.end)
            let right = config.range.end
//            return UIEdgeInsets(top: 1, left: left, bottom: 0, right: right)
            return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        }
    }
}
