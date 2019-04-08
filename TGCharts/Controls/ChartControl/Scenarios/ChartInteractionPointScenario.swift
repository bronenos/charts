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
    private let graphNode: UIView
    private let pointUpdateBlock: (CGFloat?) -> Void
    
    init(graphNode: UIView,
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
        let pointer = (point.x - graphNode.bounds.origin.x) / graphNode.bounds.size.width
        return max(0, min(pointer, 1.0))
    }
}
