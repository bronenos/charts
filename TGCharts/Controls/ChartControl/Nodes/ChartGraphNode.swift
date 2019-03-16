//
//  ChartGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGraphNode: IChartFigureNode {
    func setChart(_ chart: Chart, config: ChartConfig)
}

final class ChartGraphNode: ChartFigureNode, IChartGraphNode {
    struct Meta {
        let renderedIndices: ClosedRange<Int>
        let visibleIndices: ClosedRange<Int>
        let totalWidth: CGFloat
        let margins: ChartMargins
        let stepX: CGFloat
    }
    
    private let width: CGFloat
    
    private var figureNodes = [ChartFigureNode]()
    
    private var chart = Chart()
    private var config = ChartConfig()
    
    init(tag: String?, width: CGFloat) {
        self.width = width
        
        super.init(tag: tag ?? "[graph]")
    }
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        update()
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        self.chart = chart
        self.config = config
        update()
    }
    
    private func update() {
        removeAllChildren()
        
        guard let meta = obtainMetaForRange() else { return }
        let slice = calculateSlice(meta: meta)
        
        slice.lines.forEach { line in
            let figureNode = ChartFigureNode(tag: "graph-line")
            figureNode.setFrame(bounds)
            figureNode.setWidth(width)
            figureNode.setStrokeColor(line.color)
            figureNode.setPoints(calculatePoints(line: line, edge: slice.edge, with: meta))
            addChild(node: figureNode)
        }
    }
    
    private func obtainMetaForRange() -> Meta? {
        guard chart.length > 0 else { return nil }
        guard config.range.distance > 0 else { return nil }
        
        let lastIndex = CGFloat(chart.length - 1)
        
        let leftRenderedIndex = Int(floor(lastIndex * config.range.start))
        let rightRenderedIndex = Int(ceil(lastIndex * config.range.end))
        let renderedIndices = (leftRenderedIndex ... rightRenderedIndex)
        
        let leftVisibleIndex = Int(ceil(lastIndex * config.range.start))
        let rightVisibleIndex = Int(floor(lastIndex * config.range.end))
        let visibleIndices = (leftVisibleIndex ... rightVisibleIndex)
        
        let totalWidth = size.width / config.range.distance
        let stepX = totalWidth / lastIndex
        
        let leftRenderedItemPosition = CGFloat(leftRenderedIndex) * stepX
        let frameLeftPosition = CGFloat(totalWidth * config.range.start)

        let rightRenderedItemPosition = CGFloat(rightRenderedIndex) * stepX
        let frameRightPosition = CGFloat(totalWidth * config.range.end)
        
        return Meta(
            renderedIndices: renderedIndices,
            visibleIndices: visibleIndices,
            totalWidth: totalWidth,
            margins: ChartMargins(
                left: frameLeftPosition - leftRenderedItemPosition,
                right: rightRenderedItemPosition - frameRightPosition
            ),
            stepX: stepX
        )
    }
    
    private func calculateSlice(meta: Meta) -> ChartSlice {
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
        
        let fittingLowerValue = visibleEdges[meta.visibleIndices].map({ $0.start }).min() ?? 0
        let fittingUpperValue = visibleEdges[meta.visibleIndices].map({ $0.end }).max() ?? 0
        let fittingEdge = ChartRange(start: fittingLowerValue, end: fittingUpperValue)

        return ChartSlice(
            lines: visibleLines,
            edge: fittingEdge
        )
    }
    
    private func calculatePoints(line: ChartLine, edge: ChartRange, with meta: Meta) -> [CGPoint] {
        guard size != .zero else { return [] }
        
        let sliceValues = line.values[meta.renderedIndices]
        return sliceValues.enumerated().map { index, value in
            let x = -meta.margins.left + CGFloat(index) * meta.stepX
            let y = ((CGFloat(value) - edge.start) / (edge.end - edge.start)) * size.height
            return CGPoint(x: x, y: CGFloat(y))
        }
    }
}
