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
        let indices: ClosedRange<Int>
        let totalWidth: Double
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
        let slice = calculateSlice(indices: meta.indices)
        
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
        
        let firstIndex = Int(floor(Double(chart.length - 1) * config.range.start))
        let lastIndex = Int(ceil(Double(chart.length - 1) * config.range.end))
        let indices = (firstIndex ... lastIndex)
        let totalWidth = Double(size.width) / config.range.distance
        let stepX = CGFloat(totalWidth / Double(chart.length - 1))
        
        let firstItemPosition = CGFloat(firstIndex) * stepX
        let frameLeftPosition = CGFloat(totalWidth * config.range.start)

        let lastItemPosition = CGFloat(lastIndex) * stepX
        let frameRightPosition = CGFloat(totalWidth * config.range.end)
        
        return Meta(
            indices: indices,
            totalWidth: totalWidth,
            margins: ChartMargins(
                left: frameLeftPosition - firstItemPosition,
                right: lastItemPosition - frameRightPosition
            ),
            stepX: stepX
        )
    }
    
    private func calculateSlice(indices: ClosedRange<Int>) -> ChartSlice {
        let visibleLines: [ChartLine] = zip(chart.lines, config.lines).compactMap { line, lineConfig in
            guard lineConfig.visible else { return nil }
            return line
        }
        
        let visibleLineKeys = visibleLines.map { $0.key }
        let visibleEdges: [ChartRange] = chart.axis.map { item in
            let visibleValues = visibleLineKeys.compactMap { item.values[$0] }
            let lowerValue = CGFloat(visibleValues.min() ?? 0)
            let upperValue = CGFloat(visibleValues.max() ?? 0)
            return ChartRange(start: Double(lowerValue), end: Double(upperValue))
        }
        
        let fittingLowerValue = visibleEdges[indices].map({ $0.start }).min() ?? 0
        let fittingUpperValue = visibleEdges[indices].map({ $0.end }).max() ?? 0
        let fittingEdge = ChartRange(start: fittingLowerValue, end: fittingUpperValue)

        return ChartSlice(
            lines: visibleLines,
            edge: fittingEdge
        )
    }
    
    private func calculatePoints(line: ChartLine, edge: ChartRange, with meta: Meta) -> [CGPoint] {
        guard size != .zero else { return [] }
        
        let sliceValues = line.values[meta.indices]
        return sliceValues.enumerated().map { index, value in
            let x = -meta.margins.left + CGFloat(index) * meta.stepX
            let y = ((Double(value) - edge.start) / (edge.end - edge.start)) * Double(size.height)
            return CGPoint(x: x, y: CGFloat(y))
        }
    }
}
