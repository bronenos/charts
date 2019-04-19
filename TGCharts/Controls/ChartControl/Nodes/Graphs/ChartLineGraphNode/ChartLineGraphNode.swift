//
//  ChartLineGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartLineGraphNode: IChartGraphNode {
}

class ChartLineGraphNode: ChartGraphNode, IChartLineGraphNode {
    init(chart: Chart,
         config: ChartConfig,
         formattingProvider: IFormattingProvider,
         localeProvider: ILocaleProvider,
         width: CGFloat,
         enableControls: Bool) {
        super.init(
            chart: chart,
            config: config,
            formattingProvider: formattingProvider,
            localeProvider: localeProvider,
            enableControls: enableControls
        )
        
        configure(figure: .joinedLines) { _, node, line in
            node.strokeWidth = width
            node.minimalScaledWidth = 0.75
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var numberOfSteps: Int {
        return chart.axis.count - 1
    }
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        return false
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartLinePointsOperation(
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
        return ChartLineEyesOperation(
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
        
        for (node, line) in zip(orderedNodes, chart.lines) {
            node.points = points[line.key] ?? []
        }
    }
    
    override func updateVisibility(config: ChartConfig, duration: TimeInterval) {
        super.updateVisibility(config: config, duration: duration)
        
        zip(orderedNodes, config.lines).forEach { node, lineConfig in
            let targetAlpha = CGFloat(lineConfig.visible ? 1.0 : 0)
            if node.alpha != targetAlpha {
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
        }
    }
    
    override func updateEyes(_ eyes: [ChartGraphEye], edges: [ChartRange], duration: TimeInterval) {
        super.updateEyes(eyes, edges: edges, duration: duration)
        
        zip(orderedNodes, config.lines).forEach { node, lineConfig in
            let targetAlpha = CGFloat(lineConfig.visible ? 1.0 : 0)
            if node.alpha != targetAlpha {
                UIView.animate(withDuration: duration) { node.alpha = targetAlpha }
            }
        }
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            leftOptions: ChartGuideOptions(
                range: edges.first ?? .empty,
                numberOfSteps: 6,
                closeToBounds: false,
                textColor: DesignBook.shared.color(chart: chart, key: .y),
                reversedAnimations: false
            ),
            rightOptions: nil,
            duration: duration
        )
    }
    
    override func updatePointer(eyes: [ChartGraphEye],
                                valueEdges: [ChartRange],
                                duration: TimeInterval) {
        if let pointer = config.pointer {
            let pointing = calculatePointing(pointer: pointer, rounder: round)
            let date = chart.axis[pointing.index].date
            let lines = chart.visibleLines(config: config)
            
            container?.adjustPointer(
                pointing: pointing,
                content: ChartPointerCloudContent(
                    header: formattingProvider.format(
                        date: date,
                        style: .dayAndDate
                    ),
                    disclosable: true,
                    values: lines.map { line in
                        ChartPointerCloudValue(
                            percent: nil,
                            title: line.name,
                            value: formattingProvider.format(
                                guide: line.values[pointing.index]
                            ),
                            color: DesignBook.shared.color(
                                chart: chart,
                                key: .tooltip(line.colorKey)
                            )
                        )
                    }
                ),
                options: [.line, .dots, .closely],
                scale: eyes.first?.scaleFactor ?? 1.0,
                duration: duration *  2
            )
        }
        else {
            container?.adjustPointer(
                pointing: nil,
                content: nil,
                options: [.line, .dots],
                scale: eyes.first?.scaleFactor ?? 1.0,
                duration: duration *  2
            )
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        
        zip(chart.lines, orderedNodes).forEach { line, node in
            node.strokeColor = DesignBook.shared.color(
                chart: chart,
                key: .line(line.colorKey)
            )
        }
    }
}
