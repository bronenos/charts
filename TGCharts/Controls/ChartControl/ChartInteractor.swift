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
    func setDelegate(_ delegate: IChartInteractorDelegate?)
}

protocol IChartInteractorDelegate: class {
    func interactorDidBegin()
    func interactorDidEnd()
    func interactorDidRequestRender()
}

final class ChartInteractor: IChartInteractor {
    private(set) var range = ChartRange(start: 0.75, end: 1.0)
    private var scene: IChartSceneNode
    private weak var delegate: IChartInteractorDelegate?
    
    private let navigatorTag = "navigator"
    private let sliderTag = "navigator-slider"
    private let leftArrowTag = "slider-left-arrow"
    private let rightArrowTag = "slider-right-arrow"
    
    private var scenario: IChartInteractorScenario?

    init(scene: IChartSceneNode) {
        self.scene = scene
    }
    
    func setDelegate(_ delegate: IChartInteractorDelegate?) {
        self.delegate = delegate
    }
    
    func interactionDidStart(at point: CGPoint) {
        guard let node = scene.node(at: point) else { return }
        guard let sliderNode = scene.node(by: sliderTag) else { return }
        guard let navigatorNode = scene.node(by: navigatorTag) else { return }

        switch node.tag {
        case sliderTag:
            scenario = ChartInteractorMoveScenario(
                sceneNode: scene,
                sliderNode: sliderNode,
                navigatorNode: navigatorNode,
                startPoint: point,
                startRange: range,
                rangeUpdateBlock: { [weak self] range in self?.updateRange(range) }
            )
            
        case leftArrowTag:
            scenario = nil
            
        case rightArrowTag:
            scenario = nil

        default:
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
        delegate?.interactorDidRequestRender()
        
        let startPoint = Int(range.start * 100)
        let endPoint = Int(range.end * 100)
        print("\(#function) -> range[\(startPoint) -- \(endPoint)]")
    }
}
