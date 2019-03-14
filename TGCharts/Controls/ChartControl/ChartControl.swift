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
    private let chart: StatChart
    private(set) var config: ChartConfig

    let view: (UIView & IChartView) = ChartView()
    private var parentView: UIView?
    private weak var delegate: IChartControlDelegate?

    private let graphics: IGraphics
    private let scene: ChartSceneNode
    private let interactor: IChartInteractor
    
    init(chart: StatChart) {
        self.chart = chart
        self.config = ChartConfig(lines: chart.lines.map(startupConfigForLine))
        
        graphics = obtainGraphicsForCurrentDevice()
        scene = ChartSceneNode(tag: "scene")
        interactor = ChartInteractor(scene: scene)
        
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
        scene.setFrame(CGRect(origin: .zero, size: size))
        scene.setChart(chart, config: config, range: interactor.range)
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
    
    func interactorDidRequestRender() {
        render()
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

fileprivate extension ChartSceneNode {
    func applyDesign() {
        setBackgroundColor(
            DesignBook.shared.resolve(colorAlias: .elementRegularBackground)
        )
        
        navigatorNode.setBackgroundColor(
            DesignBook.shared.resolve(colorAlias: .elementRegularBackground)
        )
        
        navigatorNode.canvasNode.setBackgroundColor(
            DesignBook.shared.resolve(colorAlias: .sliderActiveBackground)
        )
        
        navigatorNode.graphNode.setBackgroundColor(
            DesignBook.shared.resolve(colorAlias: .sliderInactiveBackground)
        )
        
        navigatorNode.sliderNode.setForegroundColor(
            DesignBook.shared.resolve(colorAlias: .sliderControlBackground)
        )
        
        navigatorNode.sliderNode.leftArrowNode.setForegroundColor(
            DesignBook.shared.resolve(colorAlias: .sliderControlForeground)
        )
        
        navigatorNode.sliderNode.rightArrowNode.setForegroundColor(
            DesignBook.shared.resolve(colorAlias: .sliderControlForeground)
        )
    }
}
