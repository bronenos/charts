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
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat, guidable: Bool) {
        self.width = width
        
        super.init(chart: chart, config: config, formattingProvider: formattingProvider, guidable: guidable)
        
        chart.lines.forEach { line in
            let node = ChartFigureNode(figure: .joinedLines)
            node.strokeColor = line.color
            node.width = width
            graphContainer.addSubview(node)
            lineNodes[line.key] = node
        }
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
        chart.lines.forEach { line in
            guard let node = self.lineNodes[line.key] else { return }
            node.points = self.calculateNormalizedPoints(line: line, edge: edge, with: meta)
            
            if let targetVisibility = self.config.findLine(for: line.key)?.visible {
                let targetAlpha = CGFloat(targetVisibility ? 1.0 : 0)
                guard node.alpha != targetAlpha else { return }
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
        }
        
        guidesContainer.update(edge: edge, duration: duration)
        pointerContainer.update(chart: chart, config: config, meta: meta, edge: edge)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    
    private func update(duration: TimeInterval = 0) {
        guard let meta = obtainMeta(chart: chart, config: config) else { return }
        let edge = calculateSliceEdge(meta: meta)
        update(chart: chart, meta: meta, edge: edge, duration: duration)
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
    
    private func calculateNormalizedPoints(line: ChartLine, edge: ChartRange, with meta: ChartSliceMeta) -> [CGPoint] {
        guard bounds.size != .zero else { return [] }
        
        let offset = meta.totalWidth * config.range.start
        
        return line.values.enumerated().map { index, value in
            let x = -offset + meta.stepX * CGFloat(index)
            let y = bounds.calculateY(value: value, edge: edge)
            return CGPoint(x: x, y: y)
        }
    }
}
