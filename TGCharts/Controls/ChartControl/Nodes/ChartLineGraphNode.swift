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
}

class ChartLineGraphNode: ChartGraphNode, IChartLineGraphNode {
    private let width: CGFloat
    
    private var lineNodes = [String: ChartFigureNode]()
    private let pointerLineNode = ChartNode()
    
    private var calculationQueue = OperationQueue()
    private var cachedResult: CalculateOperation.Result?

    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat) {
        self.width = width
        
        super.init(chart: chart, config: config, formattingProvider: formattingProvider)
        
        calculationQueue.maxConcurrentOperationCount = 1
        calculationQueue.qualityOfService = .userInteractive
        
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
        
        if duration > 0 {
            lineNodes.values.forEach { $0.overwriteNextAnimation(duration: duration) }
        }
        
        update(duration: duration)
    }
    
    func update(chart: Chart, meta: ChartSliceMeta, edge: ChartRange, duration: TimeInterval) {
        guard bounds.size != .zero else { return }
        guard let coordsY = cachedResult?.coordsY else { return }
        
        let offset = meta.totalWidth * config.range.start
        
        chart.lines.forEach { line in
            guard let node = self.lineNodes[line.key] else { return }
            guard let coords = coordsY[line.key] else { return }
            
            node.points = line.values.enumerated().map { index, value in
                let x = -offset + meta.stepX * CGFloat(index)
                let y = coords[index]
                return CGPoint(x: x, y: y)
            }
            
            if let targetVisibility = self.config.findLine(for: line.key)?.visible {
                let targetAlpha = CGFloat(targetVisibility ? 1.0 : 0)
                guard node.alpha != targetAlpha else { return }
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
        }
        
        container?.adjustGuides([edge], duration: duration)
        container?.adjustPointer(chart: chart, config: config, meta: meta, edge: edge, options: [.line, .dots])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    
    private func update(duration: TimeInterval = 0) {
        guard let meta = obtainMeta(chart: chart, config: config) else { return }
        
        let operation = CalculateOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            completion: { [weak self] result in
                guard let `self` = self else { return }
                self.cachedResult = result
                self.update(chart: self.chart, meta: meta, edge: result.edge, duration: duration)
            }
        )
        
        if let _ = cachedResult {
            guard calculationQueue.operations.isEmpty else { return }
            calculationQueue.addOperation(operation)
        }
        else {
            let result = operation.calculateResult()
            cachedResult = result
            update(chart: chart, meta: meta, edge: result.edge, duration: duration)
        }
    }
}

fileprivate final class CalculateOperation: Operation {
    struct Result {
        let range: ChartRange
        let edge: ChartRange
        let coordsY: [String: [CGFloat]]
    }
    
    private let chart: Chart
    private let config: ChartConfig
    private let meta: ChartSliceMeta
    private let bounds: CGRect
    private let completion: ((Result) -> Void)
    
    private let callerQueue = OperationQueue.current ?? .main
    
    init(chart: Chart, config: ChartConfig, meta: ChartSliceMeta, bounds: CGRect, completion: @escaping ((Result) -> Void)) {
        self.chart = chart
        self.config = config
        self.meta = meta
        self.bounds = bounds
        self.completion = completion
    }
    
    func calculateResult() -> Result {
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
        let block = completion
        callerQueue.addOperation { block(result) }
    }
    
    private func calculateTotalEdge(lines: [ChartLine]) -> ChartRange {
        let edges: [ChartRange] = chart.axis.map { item in
            let lowerValue = CGFloat(item.values.values.min() ?? 0)
            let upperValue = CGFloat(item.values.values.max() ?? 0)
            return ChartRange(start: lowerValue, end: upperValue)
        }
        
        let fittingLowerValue = edges.map({ $0.start }).min() ?? 0
        let fittingUpperValue = edges.map({ $0.end }).max() ?? 0
        let fittingEdge = ChartRange(start: fittingLowerValue, end: fittingUpperValue)
        
        return fittingEdge
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
