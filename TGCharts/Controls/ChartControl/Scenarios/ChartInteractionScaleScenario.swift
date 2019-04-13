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
    private let sceneNode: ChartSceneNode
    private let sliderNode: UIView
    private let navigatorNode: UIView
    private let originPoint: CGPoint
    private let originFrame: CGRect
    private let startOrigin: CGFloat
    private let startRange: ChartRange
    private let direction: ChartInteractionScaleDirection
    private let navigatorOptions: ChartNavigatorOptions
    private let rangeUpdateBlock: (ChartRange) -> Void
    
    init(sceneNode: ChartSceneNode,
         sliderNode: UIView,
         navigatorNode: UIView,
         startPoint: CGPoint,
         startOrigin: CGFloat,
         startRange: ChartRange,
         direction: ChartInteractionScaleDirection,
         navigatorOptions: ChartNavigatorOptions,
         rangeUpdateBlock: @escaping (ChartRange) -> Void) {
        self.sceneNode = sceneNode
        self.sliderNode = sliderNode
        self.navigatorNode = navigatorNode
        self.originPoint = sceneNode.convert(startPoint, to: navigatorNode)
        self.originFrame = sliderNode.frame
        self.startOrigin = startOrigin
        self.startRange = startRange
        self.direction = direction
        self.navigatorOptions = navigatorOptions
        self.rangeUpdateBlock = rangeUpdateBlock
    }
    
    func interactionDidStart(at point: CGPoint, event: UIEvent?) {
    }
    
    func interactionDidMove(to point: CGPoint) {
        let standardWidth = navigatorOptions.caretStandardWidth
        let standardDistance = navigatorOptions.caretStandardDistance
        let movement = (sceneNode.convert(point, to: navigatorNode) - originPoint).dx
        
        let normalMovement: CGFloat = convert(direction) { value in
            switch value {
            case .left:
                let minimum = -originFrame.minX
                let maximum = originFrame.width - standardWidth
                return -movement.between(minimum: minimum, maximum: maximum)
                
            case .right:
                let minimum = -(originFrame.maxX - (originFrame.minX + standardWidth))
                let maximum = navigatorNode.bounds.width - originFrame.maxX
                return movement.between(minimum: minimum, maximum: maximum)
            }
        }
        
        let currentWidth = originFrame.width + normalMovement
        let growingDistanceCoef = currentWidth.percent(from: standardWidth, to: navigatorNode.bounds.width)
        let targetDistance = standardDistance + (1.0 - standardDistance) * growingDistanceCoef
        
        let range: ChartRange = convert(direction) { value in
            switch value {
            case .left:
                let start = max(0, startRange.end - targetDistance)
                return ChartRange(start: start, end: startRange.end)
                
            case .right:
                let end = min(1.0, startRange.start + targetDistance)
                return ChartRange(start: startRange.start, end: end)
            }
        }

        rangeUpdateBlock(range)
    }
    
    func interactionDidEnd(at point: CGPoint) {
    }
}
