//
//  ChartControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartControl: class {
    var view: UIView & IChartView { get }
    var config: ChartConfig { get }
    func link(to parentView: UIView)
    func setBackground(color: UIColor)
    func render()
    func toggleLine(key: String)
}

final class ChartControl: IChartControl {
    private let chart: StatChart
    private(set) var config: ChartConfig

    let view: (UIView & IChartView) = ChartView()
    
    private let graphics = obtainGraphicsForCurrentDevice()
    
    init(chart: StatChart) {
        self.chart = chart
        self.config = ChartConfig(lines: chart.lines.map(startupConfigForLine))
    }
    
    func link(to parentView: UIView) {
        view.frame = parentView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        graphics.link(to: parentView)
    }
    
    func setBackground(color: UIColor) {
        graphics.setBackground(color: color)
        graphics.render()
    }
    
    func render() {
        graphics.render()
    }
    
    func toggleLine(key: String) {
        guard let index = config.lines.firstIndex(where: { $0.key == key }) else { return }
        config.lines[index].visible.toggle()
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
