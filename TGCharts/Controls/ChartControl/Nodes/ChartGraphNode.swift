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
    struct LineMeta {
        let line: ChartLine
        let points: [CGPoint]
    }
    
    private let width: CGFloat
    
    private var lineNodes = [String: ChartFigureNode]()
    
    private(set) var chart = Chart() {
        didSet {
            guard chart != oldValue else { return }
            dirtify()
        }
    }
    
    private(set) var config = ChartConfig() {
        didSet {
            guard config != oldValue else { return }
            dirtify()
        }
    }
    
    private(set) var sideOverlap = CGFloat(0) {
        didSet {
            guard sideOverlap != oldValue else { return }
            dirtify()
        }
    }
    
    init(tag: String?, width: CGFloat, cachable: Bool) {
        self.width = width
        
        super.init(tag: tag ?? "[graph]", cachable: cachable)
    }
    
    override var frame: CGRect {
        didSet {
            update()
        }
    }
    
    func setChart(_ chart: Chart, config: ChartConfig, sideOverlap: CGFloat) {
        self.chart = chart
        self.config = config
        self.sideOverlap = sideOverlap
        update()
    }
    
    func update(meta: ChartSliceMeta, edge: ChartRange, lineMetas: [LineMeta]) {
        let usefulKeys = lineMetas.map { $0.line.key }
        let uselessKeys = Set<String>(lineNodes.keys).subtracting(usefulKeys)
        
        lineMetas.forEach { lineMeta in
            if let node = lineNodes[lineMeta.line.key] {
                node.points = lineMeta.points
            }
            else {
                let node = ChartFigureNode(tag: "graph-line", cachable: cachable)
                lineNodes[lineMeta.line.key] = node
                
                node.figure = .joinedLines
                node.frame = bounds
                node.points = lineMeta.points
                node.width = width
                node.color = lineMeta.line.color
                node.isInteractable = false
                addChild(node: node)
            }
        }
        
        uselessKeys.forEach { key in
            lineNodes.removeValue(forKey: key)?.removeFromParent()
        }
    }
    
    final func calculateY(value: Int, edge: ChartRange) -> CGFloat {
        guard size.height > 0 else { return 0 }
        return ((CGFloat(value) - edge.start) / (edge.end - edge.start)) * size.height
    }
    
    private func update() {
        guard let meta = obtainMeta(chart: chart, config: config, sideOverlap: sideOverlap) else {
            lineNodes.forEach { $0.value.removeFromParent() }
            lineNodes.removeAll()
            return
        }
        
        let lines = chart.visibleLines(config: config)
        let edge = calculateEdge(lines: lines, meta: meta)
        let lineMetas = lines.map { LineMeta(line: $0, points: slicePoints(line: $0, edge: edge, with: meta)) }
        update(meta: meta, edge: edge, lineMetas: lineMetas)
    }
    
    private func calculateEdge(lines: [ChartLine], meta: ChartSliceMeta) -> ChartRange {
        let visibleLineKeys = lines.map { $0.key }
        
        let visibleEdges: [ChartRange] = chart.axis.map { item in
            let visibleValues = visibleLineKeys.compactMap { item.values[$0] }
            let lowerValue = CGFloat(visibleValues.min() ?? 0)
            let upperValue = CGFloat(visibleValues.max() ?? 0)
            return ChartRange(start: lowerValue, end: upperValue)
        }
        
        let leftOverlappingEdge: ChartRange? = meta.leftOverlappingIndex.flatMap { index in
            let baseIndex = Int(floor(index))
            let growingPercent = index - CGFloat(baseIndex)
            
            guard baseIndex < chart.length - 1 else {
                return nil
            }
            
            let values: [CGFloat] = lines.map { line in
                let baseValue = CGFloat(line.values[baseIndex])
                let growingValue = CGFloat(line.values[baseIndex + 1])
                return baseValue + (growingValue - baseValue) * growingPercent
            }
            
            let lowerValue = CGFloat(values.min() ?? 0)
            let upperValue = CGFloat(values.max() ?? 0)
            return ChartRange(start: lowerValue, end: upperValue)
        }
        
        let rightOverlappingEdge: ChartRange? = meta.rightOverlappingIndex.flatMap { index in
            let baseIndex = Int(floor(index))
            let growingPercent = index - CGFloat(baseIndex)
            
            guard baseIndex < chart.length - 1 else {
                return nil
            }
            
            let values: [CGFloat] = lines.map { line in
                let baseValue = CGFloat(line.values[baseIndex])
                let growingValue = CGFloat(line.values[baseIndex + 1])
                return baseValue + (growingValue - baseValue) * growingPercent
            }
            
            let lowerValue = CGFloat(values.min() ?? 0)
            let upperValue = CGFloat(values.max() ?? 0)
            return ChartRange(start: lowerValue, end: upperValue)
        }
        
        let visibleEdgesSlice = visibleEdges[meta.visibleIndices]
        let overlappingEdges = [leftOverlappingEdge, rightOverlappingEdge].compactMap({ $0 })
        let edges = visibleEdgesSlice + overlappingEdges
        
        let fittingLowerValue = edges.map({ $0.start }).min() ?? 0
        let fittingUpperValue = edges.map({ $0.end }).max() ?? 0
        let fittingEdge = ChartRange(start: fittingLowerValue, end: fittingUpperValue)

        return fittingEdge
    }
    
    private func slicePoints(line: ChartLine, edge: ChartRange, with meta: ChartSliceMeta) -> [CGPoint] {
        guard size != .zero else { return [] }
        
        let sliceValues = line.values[meta.renderedIndices]
        return sliceValues.enumerated().map { index, value in
            let x = -meta.margins.left + CGFloat(index) * meta.stepX
            let y = calculateY(value: value, edge: edge)
            return CGPoint(x: x, y: CGFloat(y))
        }
    }
}
