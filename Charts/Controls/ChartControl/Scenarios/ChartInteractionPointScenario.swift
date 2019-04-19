//
//  ChartInteractionPointScenario.swift
//  TGCharts
//
//  Created by Stan Potemkin on 19/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

final class ChartInteractionPointScenario: IChartInteractorScenario {
    private let sceneNode: ChartSceneNode
    private let graphNode: UIView
    private let pointUpdateBlock: (CGFloat?) -> Void
    
    init(sceneNode: ChartSceneNode,
         graphNode: UIView,
         pointUpdateBlock: @escaping (CGFloat?) -> Void) {
        self.sceneNode = sceneNode
        self.graphNode = graphNode
        self.pointUpdateBlock = pointUpdateBlock
    }
    
    func interactionDidStart(at point: CGPoint, event: UIEvent?) {
        let graphPoint = sceneNode.convert(point, to: graphNode)
        let pointer = calculatePointer(graphPoint)
        pointUpdateBlock(pointer)
    }
    
    func interactionDidMove(to point: CGPoint) {
        let graphPoint = sceneNode.convert(point, to: graphNode)
        let pointer = calculatePointer(graphPoint)
        pointUpdateBlock(pointer)
    }
    
    func interactionDidEnd(at point: CGPoint) {
        pointUpdateBlock(nil)
    }
    
    private func calculatePointer(_ point: CGPoint) -> CGFloat {
        let pointer = (point.x - graphNode.bounds.minX) / graphNode.bounds.width
        return pointer
    }
}
