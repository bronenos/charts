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
    
    override func obtainFocusCalculationOperation(meta: ChartSliceMeta,
                                                  context: ChartFocusOperationContext,
                                                  duration: TimeInterval,
                                                  completion: @escaping (CalculateFocusResult) -> Void) -> ChartFocusOperation {
        return ChartDuoFocusOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: context,
            completion: completion
        )
    }
    
    override func updateChart(_ chart: Chart, meta: ChartSliceMeta, edges: [ChartRange], duration: TimeInterval) {
        super.updateChart(chart, meta: meta, edges: edges, duration: duration)
    }
    
    override func updateFocus(_ focuses: [UIEdgeInsets], edges: [ChartRange], duration: TimeInterval) {
        super.updateFocus(focuses, edges: edges, duration: duration)
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            left: (config.lines[0].visible ? edges.first : ChartRange(start: 0, end: 0)),
            right: (config.lines[1].visible ? edges.last : ChartRange(start: 0, end: 0)),
            duration: duration
        )
    }

    override func updatePointer(meta: ChartSliceMeta) {
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: cachedPointsResult?.context.totalEdges ?? [],
            options: [.line, .dots]
        )
    }
}
