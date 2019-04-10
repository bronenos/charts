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
    
    func update(chart: Chart, meta: ChartSliceMeta, edges: [String: ChartRange], duration: TimeInterval) {
        guard bounds.size != .zero else { return }
        guard let points = (cachedResult as? CalculateOperation.Result)?.points else { return }

        placeLines(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            points: points,
            duration: duration
        )
        
        container?.adjustGuides(
            left: visibleGuide(lineIndex: 0, edges: edges),
            right: visibleGuide(lineIndex: 1, edges: edges),
            duration: duration
        )
        
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: chart.lines.compactMap { edges[$0.key] },
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
            operation: CalculateOperation(
                chart: chart,
                config: config,
                meta: meta,
                bounds: bounds,
                completion: { [weak self] result in
                    guard let `self` = self else { return }
                    guard let `result` = result as? CalculateOperation.Result else { return }
                    
                    self.cachedResult = result
                    self.update(chart: self.chart, meta: meta, edges: result.edges, duration: duration)
                }
            ),
            duration: duration
        )
    }
    
    private func visibleGuide(lineIndex: Int, edges: [String: ChartRange]) -> ChartRange? {
        guard config.lines[lineIndex].visible else { return nil }
        return edges[config.lines[lineIndex].key]
    }
}

fileprivate final class CalculateOperation: Operation, ChartCalculateOperation {
    struct Result {
        let range: ChartRange
        let edges: [String: ChartRange]
        let points: [String: [CGPoint]]
    }
    
    private let chart: Chart
    private let config: ChartConfig
    private let meta: ChartSliceMeta
    private let bounds: CGRect
    private let completion: ((Any) -> Void)
    
    private let callerQueue = OperationQueue.current ?? .main
    
    init(chart: Chart, config: ChartConfig, meta: ChartSliceMeta, bounds: CGRect, completion: @escaping ((Any) -> Void)) {
        self.chart = chart
        self.config = config
        self.meta = meta
        self.bounds = bounds
        self.completion = completion
    }
    
    func calculateResult() -> Any {
        let edges = calculateSliceEdges(meta: meta)
        let points = calculateNormalizedPoints(edges: edges, with: meta)
        
        return Result(
            range: config.range,
            edges: edges,
            points: points
        )
    }
    
    override func main() {
        let result = calculateResult()
        let block = completion
        callerQueue.addOperation { block(result) }
    }
    
    private func calculateSliceEdges(meta: ChartSliceMeta) -> [String: ChartRange] {
        let visibleLineKeys = chart.visibleLines(config: config).map { $0.key }
        let visibleItems = chart.axis[meta.visibleIndices]
        
        var result = [String: ChartRange]()
        for key in visibleLineKeys {
            let visibleValues = visibleItems.compactMap { $0.values[key] }
            let lowerValue = CGFloat(visibleValues.min() ?? 0)
            let upperValue = CGFloat(visibleValues.max() ?? 0)
            result[key] = ChartRange(start: lowerValue, end: upperValue)
        }
        
        return result
    }
    
    private func calculateNormalizedPoints(edges: [String: ChartRange], with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        var map = [String: [CGPoint]]()
        let baseX = -(meta.totalWidth * config.range.start)
        
        chart.lines.forEach { line in
            var currentX = baseX
            map[line.key] = line.values.enumerated().map { index, value in
                defer { currentX += meta.stepX }
                
                let y = edges[line.key].flatMap({ bounds.calculateY(value: value, edge: $0) }) ?? bounds.height
                return CGPoint(x: currentX + meta.offsetX, y: y)
            }
        }
        
        return map
    }
}
