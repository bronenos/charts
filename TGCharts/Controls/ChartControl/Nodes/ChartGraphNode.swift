//
//  ChartGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGraphNode: IChartSlicableNode {
}

class ChartGraphNode: ChartNode, IChartGraphNode {
    let chart: Chart
    private(set) var config: ChartConfig
    private let width: CGFloat
    
    let linesContainer = ChartView()
    private var lineNodes = [String: ChartFigureNode]()
    
    init(chart: Chart, config: ChartConfig, width: CGFloat) {
        self.chart = chart
        self.config = config
        self.width = width
        
        super.init(frame: .zero)
        
        linesContainer.clipsToBounds = true
        addSubview(linesContainer)
        
        chart.lines.forEach { line in
            let node = ChartFigureNode(figure: .joinedLines)
            node.strokeColor = line.color
            node.width = width
            linesContainer.addSubview(node)
            lineNodes[line.key] = node
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var frame: CGRect {
        didSet { linesContainer.frame = bounds }
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        
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
    }
    
    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.primaryBackground)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 300)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    
    final func calculateY(value: Int, edge: ChartRange) -> CGFloat {
        guard bounds.size.height > 0 else { return 0 }
        guard edge.distance > 0 else { return bounds.size.height }
        return ((1.0 - (CGFloat(value) - edge.start) / (edge.end - edge.start))) * bounds.size.height
    }
    
    private func update(duration: TimeInterval = 0) {
        guard let meta = obtainMeta(chart: chart, config: config) else { return }
        let edge = calculateSliceEdge(meta: meta)
        update(chart: chart, meta: meta, edge: edge, duration: duration)
    }
    
    private func obtainEdge() -> ChartRange {
//        guard let meta = obtainMeta(chart: chart, config: config, overlap: overlap) else {
//            return ChartRange(start: 0, end: 1.0)
//        }
//
//        let lines = chart.visibleLines(config: config, addingKeys: Set())
        return calculateTotalEdge(lines: chart.lines)
    }
    
//    private func obtainVisibleKeys() -> Set<String> {
//        return Set(chart.visibleLines(config: config, addingKeys: Set()).map { $0.key })
//    }
    
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
    
//    private func slicePoints(line: ChartLine, edge: ChartRange, with meta: ChartSliceMeta) -> [CGPoint] {
//        guard size != .zero else { return [] }
//
//        let sliceValues = line.values[meta.renderedIndices]
//        return sliceValues.enumerated().map { index, value in
//            let x = -meta.margins.left + CGFloat(index) * meta.stepX
//            let y = calculateY(value: value, edge: edge)
//            return CGPoint(x: x, y: CGFloat(y))
//        }
//    }
    
    private func calculateNormalizedPoints(line: ChartLine, edge: ChartRange, with meta: ChartSliceMeta) -> [CGPoint] {
        guard bounds.size != .zero else { return [] }
        
        let offset = meta.totalWidth * config.range.start
        
        return line.values.enumerated().map { index, value in
            let x = -offset + meta.stepX * CGFloat(index)
            let y = calculateY(value: value, edge: edge)
            return CGPoint(x: x, y: y)
        }
    }
}
