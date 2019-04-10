//
//  ChartBarGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 09/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartBarGraphNode: IChartGraphNode {
    func update(chart: Chart, meta: ChartSliceMeta, edge: ChartRange, duration: TimeInterval)
}

class ChartBarGraphNode: ChartGraphNode, IChartBarGraphNode {
    private let pointerLineNode = ChartNode()
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat) {
        super.init(chart: chart, config: config, formattingProvider: formattingProvider)
        
        pointerLineNode.isHidden = true
        addSubview(pointerLineNode)
        
        configure(figure: .filledPaths) { index, node, line in
            node.fillColor = line.color
            node.layer.zPosition = -CGFloat(index)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override func update(config: ChartConfig, duration: TimeInterval) {
        super.update(config: config, duration: duration)
        update(duration: duration)
    }
    
    func update(chart: Chart, meta: ChartSliceMeta, edge: ChartRange, duration: TimeInterval) {
        guard bounds.size != .zero else { return }
        guard let blocks = (cachedResult as? CalculateOperation.Result)?.blocks else { return }
        
        placeBars(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            blocks: blocks,
            duration: duration
        )
        
        container?.adjustGuides(
            left: edge,
            right: nil,
            duration: duration
        )
        
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: chart.lines.map { _ in edge },
            options: [.line]
        )
    }
    
    func placeBars(meta: ChartSliceMeta, offset: CGFloat, blocks: [String: [CGRect]], duration: TimeInterval) {
        zip(chart.lines, config.lines).forEach { line, lineConfig in
            guard let node = lineNodes[line.key] else { return }
            
            node.bezierPaths = blocks[line.key]?.map({ UIBezierPath(rect: $0) }) ?? []
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    
    func update(duration: TimeInterval = 0) {
        let meta = chart.obtainMeta(
            config: config,
            bounds: bounds,
            offsetCoef: 0
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
                    self.update(chart: self.chart, meta: meta, edge: result.edge, duration: duration)
                }
            ),
            duration: duration
        )
    }
}

fileprivate final class CalculateOperation: Operation, ChartCalculateOperation {
    struct Result {
        let range: ChartRange
        let edge: ChartRange
        let blocks: [String: [CGRect]]
    }
    
    private let chart: Chart
    private let config: ChartConfig
    private let meta: ChartSliceMeta
    private let bounds: CGRect
    private let completion: ((Any) -> Void)
    
    private let callerQueue = OperationQueue.current ?? .main
    
    init(chart: Chart,
         config: ChartConfig,
         meta: ChartSliceMeta,
         bounds: CGRect,
         completion: @escaping ((Any) -> Void)) {
        self.chart = chart
        self.config = config
        self.meta = meta
        self.bounds = bounds
        self.completion = completion
    }
    
    func calculateResult() -> Any {
        let edge = calculateSliceEdge(meta: meta)
        let blocks = calculateNormalizedBlocks(edge: edge, with: meta)
        
        return Result(
            range: config.range,
            edge: edge,
            blocks: blocks
        )
    }
    
    override func main() {
        let result = calculateResult()
        
        if Thread.isMainThread {
            completion(result)
        }
        else {
            let block = completion
            callerQueue.addOperation { block(result) }
        }
    }
    
    private func calculateSliceEdge(meta: ChartSliceMeta) -> ChartRange {
        let visibleLineKeys = chart.visibleLines(config: config).map { $0.key }
        
        let sums: [Int] = chart.axis[meta.visibleIndices].map { item in
            let visibleValues = visibleLineKeys.compactMap { item.values[$0] }
            let summarizedValues = visibleValues.reduce(0, +)
            return summarizedValues
        }
        
        return ChartRange(start: 0, end: CGFloat(sums.max() ?? 0))
    }
    
    private func calculateNormalizedBlocks(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGRect]] {
        guard bounds.size != .zero else { return [:] }
        
        let baseX = -(meta.totalWidth * config.range.start)
        var map = [String: [CGRect]]()
        var values = [Int](repeating: 0, count: chart.axis.count)
        
        for (line, lineConfig) in zip(chart.lines, config.lines) {
            let oldValues = values
            
            if lineConfig.visible {
                line.values.enumerated().forEach { index, value in values[index] += value }
            }
            
            var currentX = baseX
            map[line.key] = zip(oldValues, values).enumerated().map { index, item in
                defer { currentX += meta.stepX }
                
                let leftX = currentX + meta.offsetX
                let lowerY = bounds.calculateY(value: item.0, edge: edge)
                let upperY = bounds.calculateY(value:  item.1, edge: edge)
                let height = (lineConfig.visible ? lowerY - upperY + bounds.height * 0.15 : 1)
                return CGRect(x: leftX, y: upperY, width: meta.stepX, height: height)
            }
        }
        
        return map
    }
}
