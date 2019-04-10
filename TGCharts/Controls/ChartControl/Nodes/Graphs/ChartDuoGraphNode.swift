//
//  ChartDuoGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartDuoGraphNode: IChartLineGraphNode {
}

class ChartDuoGraphNode: ChartLineGraphNode, IChartDuoGraphNode {
    private let pointerLineNode = ChartNode()
    
    func update(chart: Chart, meta: ChartSliceMeta, edges: [ChartRange], duration: TimeInterval) {
        guard bounds.size != .zero else { return }
        guard let points = cachedResult?.points else { return }

        placeLines(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            points: points,
            duration: duration
        )
        
        container?.adjustGuides(
            left: config.lines[0].visible ? edges[0] : nil,
            right: config.lines[1].visible ? edges[1] : nil,
            duration: duration
        )
        
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: edges,
            options: [.line, .dots]
        )
    }
    
    override func update(duration: TimeInterval = 0) {
        let meta = chart.obtainMeta(
            config: config,
            bounds: bounds,
            offsetCoef: 0.5
        )
        
        enqueueCalculation(
            operation: DuoCalculateOperation(
                chart: chart,
                config: config,
                meta: meta,
                bounds: bounds,
                completion: { [weak self] result in
                    guard let `self` = self else { return }
                    
                    self.cachedResult = result
                    self.update(chart: self.chart, meta: meta, edges: result.edges, duration: duration)
                }
            ),
            duration: duration
        )
    }
}

fileprivate final class DuoCalculateOperation: CalculateOperation {
    override func calculateResult() -> Result {
        let edges = calculateSliceEdges(meta: meta)
        let points = calculateNormalizedPoints(edges: edges, with: meta)
        
        return Result(
            range: config.range,
            edges: edges,
            points: points
        )
    }
    
    private func calculateSliceEdges(meta: ChartSliceMeta) -> [ChartRange] {
        let visibleLineKeys = chart.visibleLines(config: config).map { $0.key }
        let visibleItems = chart.axis[meta.visibleIndices]
        
        var result = [String: ChartRange]()
        for key in visibleLineKeys {
            let visibleValues = visibleItems.compactMap { $0.values[key] }
            let lowerValue = CGFloat(visibleValues.min() ?? 0)
            let upperValue = CGFloat(visibleValues.max() ?? 0)
            result[key] = ChartRange(start: lowerValue, end: upperValue)
        }
        
        return chart.lines.compactMap { result[$0.key] }
    }
    
    private func calculateNormalizedPoints(edges: [ChartRange], with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        var map = [String: [CGPoint]]()
        let baseX = -(meta.totalWidth * config.range.start)
        
        zip(chart.lines, edges).forEach { line, edge in
            var currentX = baseX
            map[line.key] = line.values.enumerated().map { index, value in
                defer { currentX += meta.stepX }
                
                let y = bounds.calculateY(value: value, edge: edge)
                return CGPoint(x: currentX + meta.offsetX, y: y)
            }
        }
        
        return map
    }
}
