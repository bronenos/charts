//
//  ChartDuoGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartDuoGraphNode: IChartGraphNode {
}

class ChartDuoGraphNode: ChartGraphNode, IChartDuoGraphNode {
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
    
    func update(chart: Chart, meta: ChartSliceMeta, edges: [String: ChartRange], duration: TimeInterval) {
        guard bounds.size != .zero else { return }
        guard let coordsY = cachedResult?.coordsY else { return }
        
        let offset = meta.totalWidth * config.range.start
        let orderedEdges = chart.lines.compactMap { edges[$0.key] }
        
        chart.lines.forEach { line in
            guard let node = lineNodes[line.key] else { return }
            guard let coords = coordsY[line.key] else { return }
            
            node.points = line.values.enumerated().map { index, value in
                let x = -offset + meta.stepX * CGFloat(index)
                let y = coords[index]
                return CGPoint(x: x, y: y)
            }
            
            if let targetVisibility = config.findLine(for: line.key)?.visible {
                let targetAlpha = CGFloat(targetVisibility ? 1.0 : 0)
                guard node.alpha != targetAlpha else { return }
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
        }
        
        container?.adjustGuides(left: visibleGuide(lineIndex: 0, edges: edges), right: visibleGuide(lineIndex: 1, edges: edges), duration: duration)
        container?.adjustPointer(chart: chart, config: config, meta: meta, edges: orderedEdges, options: [.line, .dots])
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
                self.update(chart: self.chart, meta: meta, edges: result.edges, duration: duration)
            }
        )
        
        if let _ = cachedResult {
            guard calculationQueue.operations.isEmpty else { return }
            calculationQueue.addOperation(operation)
        }
        else {
            let result = operation.calculateResult()
            cachedResult = result
            update(chart: chart, meta: meta, edges: result.edges, duration: duration)
        }
    }
    
    private func visibleGuide(lineIndex: Int, edges: [String: ChartRange]) -> ChartRange? {
        guard config.lines[lineIndex].visible else { return nil }
        return edges[config.lines[lineIndex].key]
    }
}

fileprivate final class CalculateOperation: Operation {
    struct Result {
        let range: ChartRange
        let edges: [String: ChartRange]
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
        let edges = calculateSliceEdges(meta: meta)
        let coordsY = calculateNormalizedPoints(edges: edges, with: meta)
        
        return Result(
            range: config.range,
            edges: edges,
            coordsY: coordsY
        )
    }
    
    override func main() {
        let result = calculateResult()
        let block = completion
        callerQueue.addOperation { block(result) }
    }
    
    private func calculateSliceEdges(meta: ChartSliceMeta) -> [String: ChartRange] {
        let visibleLineKeys = chart.visibleLines(config: config, addingKeys: []).map { $0.key }
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
    
    private func calculateNormalizedPoints(edges: [String: ChartRange], with meta: ChartSliceMeta) -> [String: [CGFloat]] {
        guard bounds.size != .zero else { return [:] }
        
        var map = [String: [CGFloat]]()
        for line in chart.lines {
            if let edge = edges[line.key] {
                map[line.key] = line.values.map { bounds.calculateY(value: $0, edge: edge) }
            }
            else {
                map[line.key] = [CGFloat](repeating: bounds.height, count: line.values.count)
            }
        }
        
        return map
    }
}
