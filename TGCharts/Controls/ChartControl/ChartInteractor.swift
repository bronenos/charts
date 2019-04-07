//
//  ChartInteractor.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartInteractor: IGraphicsDelegate {
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
    private var scene: ChartSceneNode
    private(set) var range: ChartRange
    private(set) var pointer: CGFloat?
    weak var delegate: IChartInteractorDelegate?
    
    private let navigatorTag = "navigator"
    private let sliderTag = "navigator-slider"
    private let leftArrowTag = "slider-left-arrow"
    private let rightArrowTag = "slider-right-arrow"
    private let graphTag = "graph"

    private var scenario: IChartInteractorScenario?

    init(scene: ChartSceneNode, range: ChartRange) {
        self.scene = scene
        self.range = range
        self.pointer = nil
    }
    
    func interactionDidStart(at point: CGPoint) {
        guard let node = scene.hitTest(point, with: nil) else { return }
        guard let sliderNode = scene.viewWithTag(ChartControlTag.slider.rawValue) else { return }
        guard let navigatorNode = scene.viewWithTag(ChartControlTag.navigator.rawValue) else { return }
        guard let graphNode = scene.viewWithTag(ChartControlTag.mainGraph.rawValue) else { return }

        switch ChartControlTag(rawValue: node.tag) ?? .unknown {
        case .slider:
            scenario = ChartInteractorMoveScenario(
                sceneNode: scene,
                sliderNode: sliderNode,
                navigatorNode: navigatorNode,
                startPoint: point,
                startRange: range,
                rangeUpdateBlock: { [weak self] range in self?.updateRange(range) }
            )

        case .leftArrow:
            scenario = ChartInteractionScaleScenario(
                sceneNode: scene,
                sliderNode: sliderNode,
                navigatorNode: navigatorNode,
                startPoint: point,
                startRange: range,
                direction: .left,
                rangeUpdateBlock: { [weak self] range in self?.updateRange(range) }
            )

        case .rightArrow:
            scenario = ChartInteractionScaleScenario(
                sceneNode: scene,
                sliderNode: sliderNode,
                navigatorNode: navigatorNode,
                startPoint: point,
                startRange: range,
                direction: .right,
                rangeUpdateBlock: { [weak self] range in self?.updateRange(range) }
            )

        case .mainGraph:
            scenario = ChartInteractionPointScenario(
                graphNode: graphNode,
                pointUpdateBlock: { [weak self] pointer in self?.updatePointer(pointer) }
            )

        default:
            print("\(#function) -> tag[\(node.tag)] scenario[-]")
            scenario = nil
        }
        
        if let scenario = scenario {
            scenario.interactionDidStart(at: point)
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
