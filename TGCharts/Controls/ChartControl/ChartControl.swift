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
    func render()
    func setBackgroundColor(_ color: UIColor)
    func toggleLine(key: String)
}

final class ChartControl: IChartControl {
    private let chart: StatChart
    private(set) var config: ChartConfig

    let view: (UIView & IChartView) = ChartView()
    private var parentView: UIView?

    private let graphics = obtainGraphicsForCurrentDevice()
    private let scene = ChartNode()
    private let graphSliceNode = ChartGraphNode()
    private let graphNavigationNode = ChartGraphNode()
    private let sliderNode = ChartSliderNode()
    
    private var range = ChartRange(startPoint: 0.15, endPoint: 0.5)
    
    init(chart: StatChart) {
        self.chart = chart
        self.config = ChartConfig(lines: chart.lines.map(startupConfigForLine))
        
        scene.addChild(node: graphSliceNode)
        scene.addChild(node: graphNavigationNode)
        graphNavigationNode.addChild(node: sliderNode)
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
    
    func render() {
        guard let size = renderingSize else { return }
        
        let bounds = CGRect(origin: .zero, size: size)
        let graphFrames = bounds.divided(atDistance: 40, from: .minYEdge)
        
        let graphSliceFrame = graphFrames.remainder
        let graphNavigationFrame = graphFrames.slice
        let sliderFrame = CGRect(x: size.width * range.startPoint, y: 0, width: size.width * range.distance, height: graphNavigationFrame.height)

        scene.setFrame(bounds)
        
        graphSliceNode.setFrame(graphSliceFrame)
        graphSliceNode.setChart(chart, config: config, range: range)
        
        graphNavigationNode.setFrame(graphNavigationFrame)
        graphNavigationNode.setBackgroundColor(DesignBook.shared.resolve(colorAlias: .sliderInactiveBackground))
        graphNavigationNode.setChart(chart, config: config, range: ChartRange.full)
        
        sliderNode.setFrame(sliderFrame)
        sliderNode.setBackgroundColor(DesignBook.shared.resolve(colorAlias: .sliderControlBackground))

        graphics.render { link in
            scene.renderWithChildren(graphics: link)
        }
    }
    
    func setBackgroundColor(_ color: UIColor) {
        scene.setBackgroundColor(color)
        render()
    }
    
    func toggleLine(key: String) {
        guard let index = config.lines.firstIndex(where: { $0.key == key }) else { return }
        config.lines[index].visible.toggle()
        render()
    }
    
    private var renderingSize: CGSize? {
        return parentView?.bounds.size
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
