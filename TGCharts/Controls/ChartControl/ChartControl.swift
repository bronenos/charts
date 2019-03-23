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

final class ChartControl: IChartControl, IChartInteractorDelegate, IChartSceneDelegate {
    private let graphics: IGraphics
    let chart: Chart
    private(set) var config: ChartConfig

    let view: (UIView & IChartView) = ChartView()
    private var outputRef: GraphicsOutputRef?
    private weak var delegate: IChartControlDelegate?

    private let uuid = UUID()
    private let scene: ChartSceneNode
    private let interactor: IChartInteractor
    
    private let startupRange = ChartRange(start: 0.75, end: 1.0)
    
    private weak var displayLink: CADisplayLink?
    private var linkAwaitingDuration = TimeInterval(0)
    private var linkTerminationDate: Date?
    
    init(graphics: IGraphics, chart: Chart, formattingProvider: IFormattingProvider) {
        self.graphics = graphics
        self.chart = chart
        self.config = startupConfig(chart: chart, range: startupRange)
        
        scene = ChartSceneNode(tag: "scene", formattingProvider: formattingProvider)
        interactor = ChartInteractor(scene: scene, range: startupRange)
        
        scene.delegate = self
        interactor.delegate = self
    }
    
    func setDelegate(_ delegate: IChartControlDelegate?) {
        self.delegate = delegate
    }
    
    func link(to parentView: UIView) {
        view.frame = parentView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parentView.addSubview(view)
        
        outputRef = graphics.link(uuid: uuid, to: view, delegate: interactor)
        scene.frame = CGRect(origin: .zero, size: view.bounds.size)
    }
    
    func unlink() {
        guard let output = outputRef else { return }
        graphics.unlink(uuid: uuid, output: output)
    }
    
    func render() {
        guard let output = outputRef else { return }
        
        scene.setChart(chart, config: config)
        graphics.render(output: output) { link in scene.renderWithChildren(output: output, graphics: link) }
        
        if linkAwaitingDuration > 0 {
            runAutoupdate(duration: linkAwaitingDuration)
            linkAwaitingDuration = 0
        }
    }
    
    func toggleLine(key: String) {
        guard let index = config.lines.firstIndex(where: { $0.key == key }) else { return }
        config.lines[index].visible.toggle()
        scene.updateChart(chart, config: config)
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
    
    private func runAutoupdate(duration: TimeInterval) {
        linkTerminationDate = Date(timeIntervalSinceNow: duration)
        
        if displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
            link.add(to: .current, forMode: .default)
            displayLink = link
        }
    }
    
    private func stopAutoupdate() {
        linkTerminationDate = nil
        displayLink?.invalidate()
    }
    
    @objc private func handleDisplayLink() {
        guard let terminationDate = linkTerminationDate else {
            stopAutoupdate()
            return
        }
        
        guard terminationDate > Date() else {
            stopAutoupdate()
            return
        }
        
        render()
    }
    
    func sceneDidRequestAnimatedRendering(duration: TimeInterval) {
        linkAwaitingDuration = max(linkAwaitingDuration, duration)
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
