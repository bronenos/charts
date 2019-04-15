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
    override var numberOfSteps: Int {
        return super.numberOfSteps
    }
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        return super.shouldReset(newConfig: newConfig, oldConfig: oldConfig)
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartDuoPointsOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: numberOfSteps,
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
    
    override func updateVisibility(config: ChartConfig, duration: TimeInterval) {
        super.updateVisibility(config: config, duration: duration)
    }
    
    override func updateEyes(_ eyes: [ChartGraphEye], edges: [ChartRange], duration: TimeInterval) {
        super.updateEyes(eyes, edges: edges, duration: duration)
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        func _constructOptions(line: ChartLine?,
                               lineConfig: ChartLineConfig?,
                               range: ChartRange?) -> ChartGuideOptions? {
            let lineColor = line.flatMap { DesignBook.shared.color(chart: chart, key: .tooltip($0.colorKey)) }
            let resultingColor = lineColor ?? DesignBook.shared.color(chart: chart, key: .y)
            
            let emptyOptions = ChartGuideOptions(
                range: .empty,
                numberOfSteps: 6,
                closeToBounds: false,
                textColor: resultingColor
            )
            
            guard let config = lineConfig, config.visible else { return emptyOptions }
            guard let range = range else { return nil }
            
            return ChartGuideOptions(
                range: range,
                numberOfSteps: 6,
                closeToBounds: false,
                textColor: resultingColor
            )
        }
        
        container?.adjustGuides(
            leftOptions: _constructOptions(
                line: chart.lines.first,
                lineConfig: config.lines.first,
                range: edges.first
            ),
            rightOptions: _constructOptions(
                line: chart.lines.last,
                lineConfig: config.lines.last,
                range: edges.last
            ),
            duration: duration
        )
    }

    override func updatePointer(eyes: [ChartGraphEye],
                                valueEdges: [ChartRange],
                                duration: TimeInterval) {
        super.updatePointer(
            eyes: eyes,
            valueEdges: valueEdges,
            duration: duration
        )
    }
}
