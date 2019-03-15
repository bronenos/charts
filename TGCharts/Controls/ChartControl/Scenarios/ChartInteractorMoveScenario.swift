//
//  ChartInteractorMoveScenario.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

final class ChartInteractorMoveScenario: IChartInteractorScenario {
    private let sliderNode: IChartNode
    private let navigatorNode: IChartNode
    private let startPoint: CGPoint
    private let originPoint: CGPoint
    private let startRange: ChartRange
    private let rangeUpdateBlock: (ChartRange) -> Void
    
    init(sceneNode: IChartSceneNode,
         sliderNode: IChartNode,
         navigatorNode: IChartNode,
         startPoint: CGPoint,
         startRange: ChartRange,
         rangeUpdateBlock: @escaping (ChartRange) -> Void) {
        self.sliderNode = sliderNode
        self.navigatorNode = navigatorNode
        self.startPoint = startPoint
        self.originPoint = sceneNode.calculateFullOrigin(of: sliderNode) ?? .zero
        self.startRange = startRange
        self.rangeUpdateBlock = rangeUpdateBlock
    }
    
    func interactionDidStart(at point: CGPoint) {
    }
    
    func interactionDidMove(to point: CGPoint) {
        let vector = point - startPoint
        let moveFactor = vector.dx / navigatorNode.size.width
        
        if moveFactor > 0 {
            let end = min(1.0, startRange.end + moveFactor)
            let range = ChartRange(start: end - startRange.distance, end: end)
            rangeUpdateBlock(range)
        }
        else {
            let start = max(0, startRange.start + moveFactor)
            let range = ChartRange(start: start, end: start + startRange.distance)
            rangeUpdateBlock(range)
        }
    }
    
    func interactionDidEnd(at point: CGPoint) {
    }
}
