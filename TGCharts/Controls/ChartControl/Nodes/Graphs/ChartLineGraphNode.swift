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
    private let width: CGFloat
    
    private let pointerLineNode = ChartNode()
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat) {
        self.width = width
        
        super.init(chart: chart, config: config, formattingProvider: formattingProvider)
        
        chart.lines.forEach { line in
            let node = ChartFigureNode(figure: .joinedLines)
            node.strokeColor = line.color
            node.width = width
            graphContainer.addSubview(node)
            lineNodes[line.key] = node
        }
        
        pointerLineNode.isHidden = true
        addSubview(pointerLineNode)
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
        guard let coordsY = (cachedResult as? CalculateOperation.Result)?.coordsY else { return }
        
        placeLines(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            coordsY: coordsY,
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
    
    func placeLines(meta: ChartSliceMeta, offset: CGFloat, coordsY: [String: [CGFloat]], duration: TimeInterval) {
        zip(chart.lines, config.lines).forEach { line, lineConfig in
            guard let node = lineNodes[line.key] else { return }
            guard let coords = coordsY[line.key] else { return }
            
            node.points = line.values.enumerated().map { index, value in
                let x = -offset + meta.stepX * CGFloat(index)
                let y = coords[index]
                return CGPoint(x: x, y: y)
            }
            
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
        guard let meta = chart.obtainMeta(config: config, bounds: bounds) else { return }
        
        let operation = CalculateOperation(
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
        )
        
        enqueueCalculation(operation: operation, duration: duration)
    }
}

fileprivate final class CalculateOperation: Operation, ChartCalculateOperation {
    struct Result {
        let range: ChartRange
        let edge: ChartRange
        let coordsY: [String: [CGFloat]]
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
        let coordsY = calculateNormalizedPoints(edge: edge, with: meta)
        
        return Result(
            range: config.range,
            edge: edge,
            coordsY: coordsY
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
        let visibleLineKeys = chart.visibleLines(config: config, addingKeys: []).map { $0.key }
        
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
    
    private func calculateNormalizedPoints(edge: ChartRange, with meta: ChartSliceMeta) -> [String: [CGFloat]] {
        guard bounds.size != .zero else { return [:] }
        
        var map = [String: [CGFloat]]()
        for line in chart.lines {
            map[line.key] = line.values.map { bounds.calculateY(value: $0, edge: edge) }
        }
        
        return map
    }
}
