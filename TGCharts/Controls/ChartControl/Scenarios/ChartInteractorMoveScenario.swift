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
    private let sceneNode: UIView
    private let sliderNode: UIView
    private let navigatorNode: UIView
    private let originPoint: CGPoint
    private let startRange: ChartRange
    private let rangeUpdateBlock: (ChartRange) -> Void
    
    init(sceneNode: UIView,
         sliderNode: UIView,
         navigatorNode: UIView,
         startPoint: CGPoint,
         startRange: ChartRange,
         rangeUpdateBlock: @escaping (ChartRange) -> Void) {
        self.sceneNode = sceneNode
        self.sliderNode = sliderNode
        self.navigatorNode = navigatorNode
        self.originPoint = sceneNode.convert(startPoint, to: navigatorNode)
        self.startRange = startRange
        self.rangeUpdateBlock = rangeUpdateBlock
    }
    
    func interactionDidStart(at point: CGPoint, event: UIEvent?) {
    }
    
    func interactionDidMove(to point: CGPoint) {
        let withinBoundWidth = navigatorNode.bounds.width - sliderNode.bounds.width
        let moveDistance = sceneNode.convert(point, to: navigatorNode) - originPoint
        let moveFactor = (moveDistance.dx / withinBoundWidth) * (1.0 - startRange.distance)
        
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
