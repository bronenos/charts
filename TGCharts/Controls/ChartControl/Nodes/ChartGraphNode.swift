//
//  ChartGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGraphNode: IChartNode {
    func setChart(_ chart: StatChart, config: ChartConfig, range: ChartRange)
}

final class ChartGraphNode: ChartNode, IChartGraphNode {
    private var chart = StatChart()
    private var config = ChartConfig()
    private var range = ChartRange(startPoint: 0, endPoint: 1.0)
    
    func setChart(_ chart: StatChart, config: ChartConfig, range: ChartRange) {
        self.chart = chart
        self.config = config
        self.range = range
    }
    
    override func render(graphics: IGraphics) {
        super.render(graphics: graphics)
        
        let focusedIndices = obtainFocusedRangeIndices()
        guard let edgeValues = calculateEdges(in: focusedIndices) else { return }
        
        chart.visibleLines(config: config).forEach { line in
            let points = calculatePoints(line: line, in: focusedIndices, edges: edgeValues)
            graphics.drawLine(points: points, color: line.color, width: 2)
        }
    }
    
    private func obtainFocusedRangeIndices() -> NSRange {
        // calculate the focused indices using ceil-round rule
        // and by one additional extra element for each side resulting in
        // line could be drawn off-the-screen
        
        let numberOfPoints: Int = 1 + Int(CGFloat(chart.size) * range.distance + 1) + 1
        let firstIndex = Int(CGFloat(chart.size) * range.startPoint)
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
