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
        let totalSumms = calculateSumms(
            chart: chart,
            config: config,
            indices: chart.axis.indices
        )
        
        let totalSummRange = ChartRange(
            start: 0,
            end: CGFloat(totalSumms.max() ?? 0)
        )
        
        let totalEdge = ChartRange(
            start: 0,
            end: 100
        )
        
        let points = calculatePoints(
            bounds: bounds,
            chart: chart,
            config: config,
            totalSumms: totalSumms,
            totalEdge: totalEdge,
            meta: meta,
            numberOfSteps: context
        )
        
        let context = ChartEyeOperationContext(
            valueEdges: [totalSummRange],
            totalEdges: [totalEdge],
            lineEdges: []
        )
        
        let eye = calculateEye(
            config: config
        )
        
        return CalculatePointsResult(
            range: config.range,
            context: context,
            points: points,
            eyes: clone(eye, number: chart.lines.count)
        )
    }
}

class ChartAreaEyesOperation: ChartEyesOperation {
    override func calculateResult() -> CalculateEyesResult {
        let eye = calculateEye(
            config: config
        )
        
        return CalculateEyesResult(
            context: context,
            edges: context.totalEdges,
            eyes: clone(eye, number: chart.lines.count)
        )
    }
}

fileprivate extension Operation {
    func calculateSumms(chart: Chart, config: ChartConfig, indices: Range<Int>) -> [Int] {
        return zip(indices, chart.axis[indices]).map { index, item in
            var summ = 0
            
            for (line, config) in zip(chart.lines, config.lines) {
                guard config.visible else { continue }
                summ += line.values[index]
            }
            
            return summ
        }
    }
    
    func calculatePoints(bounds: CGRect,
                         chart: Chart,
                         config: ChartConfig,
                         totalSumms: [Int],
                         totalEdge: ChartRange,
                         meta: ChartSliceMeta,
                         numberOfSteps: Int) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        let stepX = bounds.width / CGFloat(numberOfSteps)
        
        var map = [String: [CGPoint]]()
        var values = clone(0, number: chart.axis.count)
        
        for (line, lineConfig) in zip(chart.lines, config.lines) {
            let oldValues = values
            
            if lineConfig.visible {
                line.values.enumerated().forEach { index, value in values[index] += value }
            }
            
            var currentX = CGFloat(0)
            var points = [CGPoint]()
            
            for index in chart.axis.indices {
                let value = CGFloat(values[index])
                let summ = CGFloat(totalSumms[index])
                
                if summ > 0 {
                    let percent = Int(round((value / summ) * totalEdge.distance))
                    let currentY = bounds.calculateY(value: percent, edge: totalEdge)
                    points.append(CGPoint(x: currentX, y: currentY))
                }
                else {
                    points.append(CGPoint(x: currentX, y: bounds.height))
                }
                
                currentX += stepX
            }
            
            for index in chart.axis.indices.reversed() {
                let summ = CGFloat(totalSumms[index])
                
                currentX -= stepX
                
                if lineConfig.visible {
                    let oldValue = CGFloat(oldValues[index])
                    let percent = Int(round(oldValue / summ))
                    let currentY = bounds.calculateY(value: percent, edge: totalEdge)
                    points.append(CGPoint(x: currentX, y: currentY))
                }
                else if summ > 0 {
                    let value = CGFloat(values[index])
                    let percent = Int(round(value / summ))
                    let currentY = bounds.calculateY(value: percent, edge: totalEdge)
                    points.append(CGPoint(x: currentX, y: currentY))
                }
                else {
                    points.append(CGPoint(x: currentX, y: bounds.height))
                }
            }
            
            map[line.key] = points
        }
        
        return map
    }
    
    func calculateEye(config: ChartConfig) -> ChartGraphEye {
        let left = config.range.start
        let right = config.range.end
        let edges = UIEdgeInsets(top: 1.0, left: left, bottom: 0, right: right)
        return ChartGraphEye(edges: edges, scaleFactor: 1.0)
    }
}
