//
//  ChartControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

fileprivate let maximumDistanceBetweenDates = CGFloat(15)

protocol IChartControl: class {
    var view: UIView & IChartView { get }
    var config: ChartConfig { get }
    func link(to parentView: UIView)
    func unlink()
    func setBackground(color: UIColor)
    func render()
    func toggleLine(key: String)
}

final class ChartControl: IChartControl {
    private let chart: StatChart
    private(set) var config: ChartConfig

    let view: (UIView & IChartView) = ChartView()
    private var parentView: UIView?

    private let graphics = obtainGraphicsForCurrentDevice()
    private var focusedRange = ChartRange(startPoint: 0.15, endPoint: 0.55)
    
    private var backgroundColor = UIColor.white
    
    init(chart: StatChart) {
        self.chart = chart
        self.config = ChartConfig(lines: chart.lines.map(startupConfigForLine))
    }
    
    func link(to parentView: UIView) {
        self.parentView = parentView
        view.frame = parentView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        graphics.link(to: parentView)
    }
    
    func unlink() {
        guard let parentView = parentView else { return }
        graphics.unlink(from: parentView)
        self.parentView = nil
    }
    
    func setBackground(color: UIColor) {
        backgroundColor = color
        render()
    }
    
    func render() {
        guard let _ = renderingSize else { return }
        
        let focusedIndices = obtainFocusedRangeIndices()
        guard let edgeValues = calculateEdges(in: focusedIndices) else { return }
        
        graphics.render { link in
            link.setBackground(color: backgroundColor)
            
            chart.lines.forEach { line in
                let points = calculatePoints(line: line, in: focusedIndices, edges: edgeValues)
                link.drawLine(points: points, color: line.color, width: 2)
            }
        }
    }
    
    func toggleLine(key: String) {
        guard let index = config.lines.firstIndex(where: { $0.key == key }) else { return }
        config.lines[index].visible.toggle()
    }
    
    private var renderingSize: CGSize? {
        return parentView?.bounds.size
    }
    
    private func obtainFocusedRangeIndices() -> NSRange {
        // calculate the focused indices using ceil-round rule
        // and by one additional extra element for each side resulting in
        // line could be drawn off-the-screen
        
        let numberOfPoints: Int = 1 + Int(CGFloat(chart.size) * focusedRange.distance + 1) + 1
        let firstIndex = Int(CGFloat(chart.size) * focusedRange.startPoint)
        return NSMakeRange(firstIndex, numberOfPoints)
    }
    
    private func calculateEdges(in range: NSRange) -> ChartEdges? {
        let sliceRange = (range.lowerBound ..< range.upperBound)
        let lowerValuesPerLine = chart.lines.compactMap { $0.values[sliceRange].min() }
        let upperValuesPerLine = chart.lines.compactMap { $0.values[sliceRange].max() }
        
        guard !lowerValuesPerLine.isEmpty else { return nil }
        guard lowerValuesPerLine.count == upperValuesPerLine.count else { return nil }
        
        guard let lowerValue = lowerValuesPerLine.min() else { return nil }
        guard let upperValue = upperValuesPerLine.max() else { return nil }
        
        return ChartEdges(start: lowerValue, end: upperValue)
    }
    
    private func calculatePoints(line: StatChartLine, in range: NSRange, edges: ChartEdges) -> [CGPoint] {
        guard let size = renderingSize else { return [] }
        
        let sliceRange = (range.lowerBound ..< range.upperBound)
        let horizontalStep = size.width / CGFloat(range.length)
        
        return line.values[sliceRange].enumerated().map { index, value in
            let x = CGFloat(index) * horizontalStep
            let y = (CGFloat(value - edges.start) / CGFloat(edges.end)) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}

fileprivate func startupConfigForLine(_ line: StatChartLine) -> ChartConfigLine {
    return ChartConfigLine(
        key: line.key,
        name: line.name,
        color: line.color,
        visible: true
    )
}
