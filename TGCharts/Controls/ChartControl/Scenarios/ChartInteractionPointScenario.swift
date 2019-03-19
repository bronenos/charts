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
    private let graphNode: IChartNode
    private let pointUpdateBlock: (CGFloat?) -> Void
    
    init(graphNode: IChartNode,
         pointUpdateBlock: @escaping (CGFloat?) -> Void) {
        self.graphNode = graphNode
        self.pointUpdateBlock = pointUpdateBlock
    }
    
    func interactionDidStart(at point: CGPoint) {
        let pointer = calculatePointer(point)
        pointUpdateBlock(pointer)
    }
    
    func interactionDidMove(to point: CGPoint) {
        let pointer = calculatePointer(point)
        pointUpdateBlock(pointer)
    }
    
    func interactionDidEnd(at point: CGPoint) {
        pointUpdateBlock(nil)
    }
    
    private func calculatePointer(_ point: CGPoint) -> CGFloat {
        return (point.x - graphNode.origin.x) / graphNode.size.width
    }
}

