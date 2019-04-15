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
    func interactionDidStart(at point: CGPoint, event: UIEvent?)
    func interactionDidMove(to point: CGPoint)
    func interactionDidEnd(at point: CGPoint)
}

protocol IChartControlDelegate: class {
    func chartControlDidBeginInteraction()
    func chartControlDidEndInteraction()
}

protocol IChartControl: class {
    var chart: Chart { get }
    var config: ChartConfig { get }
    func setDelegate(_ delegate: IChartControlDelegate?)
    func link(to parentView: UIView)
    func unlink()
    func updateHeight(mainGraphHeight: CGFloat)
    func update()
}

final class ChartControl: UIView, IChartControl, IChartInteractorDelegate, IChartSceneDelegate {
    let chart: Chart

    private weak var delegate: IChartControlDelegate?

    private let uuid = UUID()
    private let scene: ChartSceneNode
    private let interactor: IChartInteractor
    
    private let standardDistance: CGFloat
    private let standardRange: ChartRange
    private let navigatorOptions: ChartNavigatorOptions
    private(set) var config: ChartConfig

    init(chart: Chart, mainGraphHeight: CGFloat, localeProvider: ILocaleProvider, formattingProvider: IFormattingProvider) {
        self.chart = chart
        
        standardDistance = CGFloat(1.0 / 12.0)
        standardRange = ChartRange(start: 1.0 - standardDistance, end: 1.0)

        navigatorOptions = ChartNavigatorOptions(
            caretStandardDistance: standardDistance
        )
        
        config = startupConfig(
            chart: chart,
            standardDistance: standardDistance,
            range: standardRange
        )
        
        scene = ChartSceneNode(
            chart: chart,
            mainGraphHeight: mainGraphHeight,
            navigatorOptions: navigatorOptions,
            config: config,
            localeProvider: localeProvider,
            formattingProvider: formattingProvider
        )
        
        interactor = ChartInteractor(
            scene: scene,
            navigatorOptions: navigatorOptions,
            range: standardRange
        )
        
        super.init(frame: .zero)
        
        addSubview(scene)
        
        scene.delegate = self
        interactor.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var frame: CGRect {
        didSet { update() }
    }
    
    func setDelegate(_ delegate: IChartControlDelegate?) {
        self.delegate = delegate
    }
    
    func link(to parentView: UIView) {
        frame = parentView.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parentView.addSubview(self)
        
        scene.frame = CGRect(origin: .zero, size: bounds.size)
        render(duration: 0, wantsActualEye: false)
    }
    
    func unlink() {
        removeFromSuperview()
    }
    
    func updateHeight(mainGraphHeight: CGFloat) {
        scene.updateHeight(mainGraphHeight: mainGraphHeight)
        render(duration: 0, wantsActualEye: false)
        setNeedsLayout()
    }
    
    func update() {
        scene.updateDesign()
        render(duration: 0, wantsActualEye: false)
    }
    
    func sceneDidToggleLine(index: Int, exclusive: Bool) {
        if exclusive {
            config.lines.indices.forEach {  config.lines[$0].visible = false }
            config.lines[index].visible = true
        }
        else {
            config.lines[index].visible.toggle()
        }
        
        render(
            duration: DesignBook.shared.duration(.toggleLine),
            wantsActualEye: true
        )
    }
    
    func interactorDidBegin() {
        delegate?.chartControlDidBeginInteraction()
    }
    
    func interactorDidEnd() {
        delegate?.chartControlDidEndInteraction()
    }
    
    func interactorDidInformToUpdate(wantsActualEye: Bool) {
        config.range = interactor.range
        config.pointer = interactor.pointer
        
        render(
            duration: DesignBook.shared.duration(.updateEye),
            wantsActualEye: wantsActualEye
        )
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return scene.sizeThatFits(size)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            interactor.interactionDidStart(at: point, event: event)
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
    
    private func render(duration: TimeInterval, wantsActualEye: Bool) {
        scene.update(config: config, duration: duration, wantsActualEye: wantsActualEye)
    }
}

fileprivate func startupConfig(chart: Chart, standardDistance: CGFloat, range: ChartRange) -> ChartConfig {
    return ChartConfig(
        standardDistance: standardDistance,
        lines: chart.lines.map { line in
            ChartLineConfig(key: line.key, visible: true)
        },
        range: range,
        pointer: nil
    )
}
