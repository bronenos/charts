//
//  ChartDuoGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartDuoGraphNode: IChartLineGraphNode {
}

class ChartDuoGraphNode: ChartLineGraphNode, IChartDuoGraphNode {
    private let pointerLineNode = ChartNode()
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        return super.shouldReset(newConfig: newConfig, oldConfig: oldConfig)
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   date: Date,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartDuoPointsOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: date,
            completion: completion
        )
    }
    
    override func obtainEyesCalculationOperation(meta: ChartSliceMeta,
                                                  context: ChartEyeOperationContext,
                                                  duration: TimeInterval,
                                                  completion: @escaping (CalculateEyesResult) -> Void) -> ChartEyesOperation {
        return ChartDuoEyesOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: context,
            completion: completion
        )
    }
    
    override func updateChart(points: [String: [CGPoint]]) {
        super.updateChart(points: points)
    }
    
    override func updateEyes(_ eyes: [ChartGraphEye], edges: [ChartRange], duration: TimeInterval) {
        super.updateEyes(eyes, edges: edges, duration: duration)
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            left: (config.lines.first?.visible == true ? edges.first : .empty),
            right: (config.lines.last?.visible == true ? edges.last : .empty),
            duration: duration
        )
    }

    override func updatePointer(meta: ChartSliceMeta, totalEdges: [ChartRange]) {
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: totalEdges,
            options: [.line, .dots]
        )
    }
}
