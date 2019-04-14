//
//  ChartInteractor.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartInteractor: IChartInteracting {
    var range: ChartRange { get }
    var pointer: CGFloat? { get }
    var delegate: IChartInteractorDelegate? { get set }
}

protocol IChartInteractorDelegate: class {
    func interactorDidBegin()
    func interactorDidEnd()
    func interactorDidInformToUpdate()
}

final class ChartInteractor: IChartInteractor {
    private let scene: ChartSceneNode
    private let navigatorOptions: ChartNavigatorOptions
    private(set) var range: ChartRange
    private(set) var pointer: CGFloat?
    weak var delegate: IChartInteractorDelegate?
    
    private let navigatorTag = "navigator"
    private let sliderTag = "navigator-slider"
    private let leftArrowTag = "slider-left-arrow"
    private let rightArrowTag = "slider-right-arrow"
    private let graphTag = "graph"

    private var scenario: IChartInteractorScenario?

    init(scene: ChartSceneNode, navigatorOptions: ChartNavigatorOptions, range: ChartRange) {
        self.scene = scene
        self.navigatorOptions = navigatorOptions
        self.range = range
        self.pointer = nil
    }
    
    func interactionDidStart(at point: CGPoint, event: UIEvent?) {
        guard let node = scene.hitTest(point, with: nil) else { return }
        guard let sliderNode = scene.viewWithTag(ChartControlTag.slider.rawValue) else { return }
        guard let navigatorNode = scene.viewWithTag(ChartControlTag.navigator.rawValue) else { return }
        guard let graphNode = scene.viewWithTag(ChartControlTag.graph.rawValue) else { return }

        switch ChartControlTag(rawValue: node.tag) ?? .unknown {
        case .slider:
            scenario = ChartInteractorMoveScenario(
                sceneNode: scene,
                sliderNode: sliderNode,
                navigatorNode: navigatorNode,
                startPoint: point,
                startRange: range,
                rangeUpdateBlock: { [weak self] range in
                    self?.updateRange(range)
                }
            )

        case .leftArrow:
            scenario = ChartInteractionScaleScenario(
                sceneNode: scene,
                sliderNode: sliderNode,
                navigatorNode: navigatorNode,
                startPoint: point,
                startOrigin: scene.convert(point, to: sliderNode).x,
                startRange: range,
                direction: .left,
                navigatorOptions: navigatorOptions,
                rangeUpdateBlock: { [weak self] range in
                    self?.updateRange(range)
                }
            )

        case .rightArrow:
            scenario = ChartInteractionScaleScenario(
                sceneNode: scene,
                sliderNode: sliderNode,
                navigatorNode: navigatorNode,
                startPoint: point,
                startOrigin: scene.convert(point, to: sliderNode).x,
                startRange: range,
                direction: .right,
                navigatorOptions: navigatorOptions,
                rangeUpdateBlock: { [weak self] range in
                    self?.updateRange(range)
                }
            )

        case .graph:
            scenario = ChartInteractionPointScenario(
                sceneNode: scene,
                graphNode: graphNode,
                pointUpdateBlock: { [weak self] pointer in
                    self?.updatePointer(pointer)
                }
            )

        default:
            scenario = nil
        }
        
        if let scenario = scenario {
            scenario.interactionDidStart(at: point, event: event)
            delegate?.interactorDidBegin()
        }
    }
    
    func interactionDidMove(to point: CGPoint) {
        scenario?.interactionDidMove(to: point)
    }
    
    func interactionDidEnd(at point: CGPoint) {
        scenario?.interactionDidEnd(at: point)
        delegate?.interactorDidEnd()
    }
    
    private func updateRange(_ range: ChartRange) {
        self.range = range
        delegate?.interactorDidInformToUpdate()
    }
    
    private func updatePointer(_ pointer: CGFloat?) {
        self.pointer = pointer
        delegate?.interactorDidInformToUpdate()
    }
}
