//
//  ChartControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartInteracting: class {
    func interactionDidStart(at point: CGPoint)
    func interactionDidMove(to point: CGPoint)
    func interactionDidEnd(at point: CGPoint)
}

protocol IChartControl: class {
    var chart: Chart { get }
    var config: ChartConfig { get }
    func setDelegate(_ delegate: IChartControlDelegate?)
    func link(to parentView: UIView)
    func unlink()
    func toggleLine(key: String)
    func update()
}

protocol IChartControlDelegate: class {
    func chartControlDidBeginInteraction()
    func chartControlDidEndInteraction()
}

final class ChartControl: UIView, IChartControl, IChartInteractorDelegate, IChartSceneDelegate {
    let chart: Chart
    private(set) var config: ChartConfig

    private weak var delegate: IChartControlDelegate?

    private let uuid = UUID()
    private let scene: ChartSceneNode
    private let interactor: IChartInteractor
    
    private let startupRange = ChartRange(start: 0.75, end: 1.0)
    
    init(chart: Chart, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = startupConfig(chart: chart, range: startupRange)
        self.scene = ChartSceneNode(chart: chart, config: config, formattingProvider: formattingProvider)
        self.interactor = ChartInteractor(scene: scene, range: startupRange)
        
        super.init(frame: .zero)
        
        addSubview(scene)
        
        scene.delegate = self
        interactor.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func setDelegate(_ delegate: IChartControlDelegate?) {
        self.delegate = delegate
    }
    
    func link(to parentView: UIView) {
        frame = parentView.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parentView.addSubview(self)
        
        scene.frame = CGRect(origin: .zero, size: bounds.size)
    }
    
    func unlink() {
        removeFromSuperview()
    }
    
    func render(duration: TimeInterval = 0) {
        scene.update(config: config, duration: duration)
    }
    
    func toggleLine(key: String) {
        guard let index = config.lines.firstIndex(where: { $0.key == key }) else { return }
        
        config.lines[index].visible.toggle()
        render(duration: 0.25)
    }
    
    func update() {
        scene.updateDesign()
        render()
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            interactor.interactionDidStart(at: point)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            interactor.interactionDidMove(to: point)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            interactor.interactionDidEnd(at: point)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            interactor.interactionDidEnd(at: point)
        }
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
