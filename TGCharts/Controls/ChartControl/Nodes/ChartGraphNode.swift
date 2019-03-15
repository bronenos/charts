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
    private var figureNodes = [ChartFigureNode]()
    
    private var chart = Chart()
    private var config = ChartConfig()
    
    override init(tag: String?) {
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
        
        let indices = obtainFocusedRangeIndices()
        let slice = calculateSlice(indices: indices)
        
        slice.lines.forEach { line in
            let figureNode = ChartFigureNode(tag: "graph-line")
            figureNode.setFrame(bounds)
            figureNode.setWidth(2)
            figureNode.setStrokeColor(line.color)
            figureNode.setPoints(calculatePoints(line: line, edge: slice.edge, in: indices))
            addChild(node: figureNode)
        }
    }
    
    private func obtainFocusedRangeIndices() -> NSRange {
        // calculate the focused indices using ceil-round rule
        // and by one additional extra element for each side resulting in
        // line could be drawn off-the-screen
        
        let numberOfPoints = Int(ceil(CGFloat(chart.length) * config.range.distance))
        let firstIndex = Int(floor(CGFloat(chart.length) * config.range.start))
        let restNumber = min(chart.length - firstIndex, numberOfPoints)
        return NSMakeRange(firstIndex, restNumber)
    }
    
    func calculateSlice(indices: NSRange) -> ChartSlice {
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
        
        let visibleRange = (indices.lowerBound ..< indices.upperBound)
        let fittingLowerValue = visibleEdges[visibleRange].map({ $0.start }).min() ?? 0
        let fittingUpperValue = visibleEdges[visibleRange].map({ $0.end }).max() ?? 0
        let fittingEdge = ChartRange(start: fittingLowerValue, end: fittingUpperValue)

        return ChartSlice(
            lines: visibleLines,
            edge: fittingEdge
        )
    }
    
    private func calculatePoints(line: ChartLine, edge: ChartRange, in range: NSRange) -> [CGPoint] {
        guard size != .zero else { return [] }
        
        let sliceRange = (range.lowerBound ..< range.upperBound)
        let horizontalStep = size.width / CGFloat(range.length)
        
        let sliceValues = line.values[sliceRange]
        return sliceValues.enumerated().map { index, value in
            let x = CGFloat(index) * horizontalStep
            let y = ((CGFloat(value) - edge.start) / (edge.end - edge.start)) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}
