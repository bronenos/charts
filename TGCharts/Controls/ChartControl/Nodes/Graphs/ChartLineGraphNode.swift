//
//  ChartLineGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartLineGraphNode: IChartGraphNode {
    func update(chart: Chart, meta: ChartSliceMeta, edge: ChartRange, duration: TimeInterval)
}

class ChartLineGraphNode: ChartGraphNode, IChartLineGraphNode {
    private let pointerLineNode = ChartNode()
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat) {
        super.init(chart: chart, config: config, formattingProvider: formattingProvider)
        
        pointerLineNode.isHidden = true
        addSubview(pointerLineNode)
        
        configure(figure: .joinedLines) { _, node, line in
            node.strokeColor = line.color
            node.width = width
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
        guard let points = (cachedResult as? CalculateOperation.Result)?.points else { return }
        
        placeLines(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            points: points,
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
            options: [.line, .dots]
        )
    }
    
    func placeLines(meta: ChartSliceMeta, offset: CGFloat, points: [String: [CGPoint]], duration: TimeInterval) {
        zip(chart.lines, config.lines).forEach { line, lineConfig in
            guard let node = lineNodes[line.key] else { return }
            
            node.points = points[line.key] ?? []
            
            let targetAlpha = CGFloat(lineConfig.visible ? 1.0 : 0)
            if node.alpha != targetAlpha {
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
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
        let points: [String: [CGPoint]]
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
        let points = calculateNormalizedPoints(edge: edge, with: meta)
        
        return Result(
            range: config.range,
            edge: edge,
            points: points
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
        
        let edges: [ChartRange] = chart.axis[meta.visibleIndices].map { item in
            let visibleValues = visibleLineKeys.compactMap { item.values[$0] }
            let lowerValue = CGFloat(visibleValues.min() ?? 0)
            let upperValue = CGFloat(visibleValues.max() ?? 0)
            return ChartRange(start: lowerValue, end: upperValue)
        }
        
        let fittingLowerValue = edges.map({ $0.start }).min() ?? 0
        let fittingUpperValue = edges.map({ $0.end }).max() ?? 0
        let fittingEdge = ChartRange(start: fittingLowerValue, end: fittingUpperValue)
        
        return fittingEdge
    }
    
    private func calculateNormalizedPoints(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGPoint]] {
        guard bounds.size != .zero else { return [:] }
        
        var map = [String: [CGPoint]]()
        let baseX = -(meta.totalWidth * config.range.start)
        
        for line in chart.lines {
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
