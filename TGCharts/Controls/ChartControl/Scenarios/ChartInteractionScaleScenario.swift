//
//  ChartInteractionScaleScenario.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum ChartInteractionScaleDirection {
    case left
    case right
}

final class ChartInteractionScaleScenario: IChartInteractorScenario {
    private let sliderNode: UIView
    private let navigatorNode: UIView
    private let startPoint: CGPoint
    private let originPoint: CGPoint
    private let startRange: ChartRange
    private let direction: ChartInteractionScaleDirection
    private let rangeUpdateBlock: (ChartRange) -> Void
    
    private let minimalRangeDistance = CGFloat(0.1)
    
    init(sceneNode: IChartSceneNode,
         sliderNode: UIView,
         navigatorNode: UIView,
         startPoint: CGPoint,
         startRange: ChartRange,
         direction: ChartInteractionScaleDirection,
         rangeUpdateBlock: @escaping (ChartRange) -> Void) {
        self.sliderNode = sliderNode
        self.navigatorNode = navigatorNode
        self.startPoint = startPoint
        self.originPoint = sliderNode.convert(.zero, to: nil)
        self.startRange = startRange
        self.direction = direction
        self.rangeUpdateBlock = rangeUpdateBlock
    }
    
    func interactionDidStart(at point: CGPoint, event: UIEvent?) {
    }
    
    func interactionDidMove(to point: CGPoint) {
        let vector = point - startPoint
        let moveFactor = vector.dx / navigatorNode.bounds.size.width
        
        switch direction {
        case .left:
            let limit = startRange.end - minimalRangeDistance
            let start = max(0, min(limit, startRange.start + moveFactor))
            let range = ChartRange(start: start, end: startRange.end)
            rangeUpdateBlock(range)

        case .right:
            let limit = startRange.start + minimalRangeDistance
            let end = min(1.0, max(limit, startRange.end + moveFactor))
            let range = ChartRange(start: startRange.start, end: end)
            rangeUpdateBlock(range)
        }
    }
    
    func interactionDidEnd(at point: CGPoint) {
    }
}

