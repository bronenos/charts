//
//  ChartGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGraphNode: IChartFigureNode, IChartSlicableNode {
}

final class ChartGraphNode: ChartFigureNode, IChartGraphNode {
    private let width: CGFloat
    
    private var figureNodes = [ChartFigureNode]()
    
    private var chart = Chart()
    private var config = ChartConfig()
    private var sideOverlap = CGFloat(0)
    
    init(tag: String?, width: CGFloat) {
        self.width = width
        
        super.init(tag: tag ?? "[graph]")
    }
    
    override var frame: CGRect {
        didSet { update() }
    }
    
    func setChart(_ chart: Chart, config: ChartConfig, sideOverlap: CGFloat) {
        self.chart = chart
        self.config = config
        self.sideOverlap = sideOverlap
        update()
    }
    
    private func update() {
        removeAllChildren()
        
        guard let meta = obtainMeta(chart: chart, config: config, sideOverlap: sideOverlap) else { return }
        let slice = calculateSlice(meta: meta)
        
        slice.lines.forEach { line in
            let figureNode = ChartFigureNode(tag: "graph-line")
            figureNode.frame = bounds
            figureNode.points = slicePoints(line: line, edge: slice.edge, with: meta)
            figureNode.strokeWidth = width
            figureNode.strokeColor = line.color
            addChild(node: figureNode)
        }
    }
    
    private func calculateSlice(meta: ChartSliceMeta) -> ChartSlice {
        let visibleLines: [ChartLine] = zip(chart.lines, config.lines).compactMap { line, lineConfig in
            guard lineConfig.visible else { return nil }
            return line
        }
        
        let visibleLineKeys = visibleLines.map { $0.key }
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
            
            let values: [CGFloat] = visibleLines.map { line in
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
            
            let values: [CGFloat] = visibleLines.map { line in
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

        return ChartSlice(
            lines: visibleLines,
            edge: fittingEdge
        )
    }
    
    private func slicePoints(line: ChartLine, edge: ChartRange, with meta: ChartSliceMeta) -> [CGPoint] {
        guard size != .zero else { return [] }
        
        let sliceValues = line.values[meta.renderedIndices]
        return sliceValues.enumerated().map { index, value in
            let x = -meta.margins.left + CGFloat(index) * meta.stepX
            let y = ((CGFloat(value) - edge.start) / (edge.end - edge.start)) * size.height
            return CGPoint(x: x, y: CGFloat(y))
        }
    }
}
