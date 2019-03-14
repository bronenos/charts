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
    func setChart(_ chart: StatChart, config: ChartConfig, range: ChartRange)
}

final class ChartGraphNode: ChartFigureNode, IChartGraphNode {
    private var figureNodes = [ChartFigureNode]()
    
    private var chart = StatChart()
    private var config = ChartConfig()
    private var range = ChartRange(start: 0, end: 1.0)
    
    override init(tag: String?) {
        super.init(tag: tag ?? "[graph]")
    }
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        update()
    }
    
    func setChart(_ chart: StatChart, config: ChartConfig, range: ChartRange) {
        self.chart = chart
        self.config = config
        self.range = range
        update()
    }
    
    private func update() {
        removeAllChildren()
        
        let focusedIndices = obtainFocusedRangeIndices()
        guard let edgeValues = calculateEdges(in: focusedIndices) else { return }
        
        chart.visibleLines(config: config).forEach { line in
            let figureNode = ChartFigureNode(tag: "graph-line")
            figureNode.setFrame(bounds)
            figureNode.setWidth(2)
            figureNode.setStrokeColor(line.color)
            figureNode.setPoints(calculatePoints(line: line, in: focusedIndices, edges: edgeValues))
            addChild(node: figureNode)
        }
    }
    
    private func obtainFocusedRangeIndices() -> NSRange {
        // calculate the focused indices using ceil-round rule
        // and by one additional extra element for each side resulting in
        // line could be drawn off-the-screen
        
        let numberOfPoints: Int = 1 + Int(CGFloat(chart.size) * range.distance + 1) + 1
        let firstIndex = Int(CGFloat(chart.size) * range.start)
        let restNumber = min(chart.size - firstIndex, numberOfPoints)
        return NSMakeRange(firstIndex, restNumber)
    }
    
    private func calculateEdges(in range: NSRange) -> ChartEdges? {
        let sliceRange = (range.lowerBound ..< range.upperBound)
        let lowerValuesPerLine = chart.visibleLines(config: config).compactMap { $0.values[sliceRange].min() }
        let upperValuesPerLine = chart.visibleLines(config: config).compactMap { $0.values[sliceRange].max() }
        
        guard !lowerValuesPerLine.isEmpty else { return nil }
        guard lowerValuesPerLine.count == upperValuesPerLine.count else { return nil }
        
        guard let lowerValue = lowerValuesPerLine.min() else { return nil }
        guard let upperValue = upperValuesPerLine.max() else { return nil }
        
        return ChartEdges(start: lowerValue, end: upperValue)
    }
    
    private func calculatePoints(line: StatChartLine, in range: NSRange, edges: ChartEdges) -> [CGPoint] {
        guard size != .zero else { return [] }
        
        let sliceRange = (range.lowerBound ..< range.upperBound)
        let horizontalStep = size.width / CGFloat(range.length)
        
        return line.values[sliceRange].enumerated().map { index, value in
            let x = CGFloat(index) * horizontalStep
            let y = (CGFloat(value - edges.start) / CGFloat(edges.end - edges.start)) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}
