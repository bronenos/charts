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
    var chart: Chart { get }
    var config: ChartConfig { get }
    func setDelegate(_ delegate: IChartControlDelegate?)
    func link(to parentView: UIView)
    func unlink()
    func render()
    func toggleLine(key: String)
}

protocol IChartControlDelegate: class {
    func chartControlDidBeginInteraction()
    func chartControlDidEndInteraction()
}

final class ChartControl: IChartControl, IChartInteractorDelegate {
    let chart: Chart
    private(set) var config: ChartConfig

    let view: (UIView & IChartView) = ChartView()
    private var parentView: UIView?
    private weak var delegate: IChartControlDelegate?

    private let graphics: IGraphics
    private let scene: ChartSceneNode
    private let interactor: IChartInteractor
    
    private let startupRange = ChartRange(start: 0.75, end: 1.0)
    
    init(chart: Chart, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = startupConfig(chart: chart, range: startupRange)
        
        graphics = obtainGraphicsForCurrentDevice()
        scene = ChartSceneNode(tag: "scene", formattingProvider: formattingProvider)
        interactor = ChartInteractor(scene: scene, range: startupRange)
        
        graphics.setDelegate(interactor)
        interactor.setDelegate(self)
    }
    
    func setDelegate(_ delegate: IChartControlDelegate?) {
        self.delegate = delegate
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
        
        scene.frame = CGRect(origin: .zero, size: size)
        scene.setChart(chart, config: config)
        scene.applyDesign()
        graphics.render { link in scene.renderWithChildren(graphics: link)}
    }
    
    func toggleLine(key: String) {
        guard let index = config.lines.firstIndex(where: { $0.key == key }) else { return }
        config.lines[index].visible.toggle()
        render()
    }
    
    private var renderingSize: CGSize? {
        return parentView?.bounds.size
    }
    
    func interactorDidBegin() {
        delegate?.chartControlDidBeginInteraction()
    }
    
    func interactorDidEnd() {
        delegate?.chartControlDidEndInteraction()
    }
    
    func interactorDidInformToUpdate() {
        config.range = interactor.range
        config.pointer = interactor.pointer
        render()
    }
}

fileprivate func startupConfig(chart: Chart, range: ChartRange) -> ChartConfig {
    return ChartConfig(
        lines: chart.lines.map { line in
            ChartLineConfig(key: line.key, visible: true)
        },
        range: range,
        pointer: nil
    )
}

fileprivate extension ChartSceneNode {
    func applyDesign() {
        backgroundColor = (
            DesignBook.shared.resolve(colorAlias: .elementRegularBackground)
        )
        
        navigatorNode.backgroundColor = (
            DesignBook.shared.resolve(colorAlias: .elementRegularBackground)
        )
        
        navigatorNode.backgroundColor = (
            DesignBook.shared.resolve(colorAlias: .sliderActiveBackground)
        )
        
        navigatorNode.graphNode.backgroundColor = (
            DesignBook.shared.resolve(colorAlias: .sliderInactiveBackground)
        )
        
        navigatorNode.sliderNode.foregroundColor = (
            DesignBook.shared.resolve(colorAlias: .sliderControlBackground)
        )
        
        navigatorNode.sliderNode.leftArrowNode.foregroundColor = (
            DesignBook.shared.resolve(colorAlias: .sliderControlForeground)
        )
        
        navigatorNode.sliderNode.rightArrowNode.foregroundColor = (
            DesignBook.shared.resolve(colorAlias: .sliderControlForeground)
        )
    }
}
