//
//  ChartAreaGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartAreaGraphNode: IChartGraphNode {
}

class ChartAreaGraphNode: ChartGraphNode, IChartAreaGraphNode {
    override init(chart: Chart,
                  config: ChartConfig,
                  formattingProvider: IFormattingProvider,
                  localeProvider: ILocaleProvider,
                  enableControls: Bool) {
        super.init(
            chart: chart,
            config: config,
            formattingProvider: formattingProvider,
            localeProvider: localeProvider,
            enableControls: enableControls
        )
        
        configure(figure: .filledPaths) { index, node, line in
            node.layer.zPosition = -CGFloat(index)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var numberOfSteps: Int {
        return chart.axis.count - 1
    }
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        let newVisible = newConfig.lines.map { $0.visible }
        let oldVisible = oldConfig.lines.map { $0.visible }
        return (newVisible != oldVisible)
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartAreaPointsOperation(
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
        return ChartAreaEyesOperation(
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
        
        zip(chart.lines, config.lines).forEach { line, lineConfig in
            guard let node = figureNodes[line.key] else { return }
            
            if let point = points[line.key] {
                guard let firstPoint = point.first else { return }
                let restPoints = point.dropFirst()
                
                let path = UIBezierPath()
                path.move(to: firstPoint)
                restPoints.forEach(path.addLine)
                path.close()
                
                node.bezierPaths = [path]
            }
            else {
                node.bezierPaths = []
            }
        }
    }
    
    override func updateVisibility(config: ChartConfig, duration: TimeInterval) {
        super.updateVisibility(config: config, duration: duration)
    }
    
    override func updateEyes(_ eyes: [ChartGraphEye], edges: [ChartRange], duration: TimeInterval) {
        super.updateEyes(eyes, edges: edges, duration: duration)
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            leftOptions: ChartGuideOptions(
                range: edges.first ?? .empty,
                numberOfSteps: 5,
                closeToBounds: true,
                textColor: DesignBook.shared.color(chart: chart, key: .y)
            ),
            rightOptions: nil,
            duration: duration
        )
    }
    
    override func updatePointer(eyes: [ChartGraphEye],
                                valueEdges: [ChartRange],
                                duration: TimeInterval) {
        if let pointer = config.pointer, let topValue = valueEdges.first?.end {
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
                        let percent = CGFloat(line.values[pointing.index]) / CGFloat(topValue)
                        let percentToDisplay = Int(percent * 100)
                        
                        return ChartPointerCloudValue(
                            percent: formattingProvider.format(
                                guide: percentToDisplay
                            ),
                            title: line.name,
                            value: formattingProvider.format(
                                guide: line.values[pointing.index]
                            ),
                            color: DesignBook.shared.color(chart: chart, key: .tooltip(line.colorKey))
                        )
                    }
                ),
                options: [.line, .anchor],
                duration: duration *  2
            )
        }
        else {
            container?.adjustPointer(
                pointing: nil,
                content: nil,
                options: [.line, .anchor],
                duration: duration *  2
            )
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        
        zip(chart.lines, orderedNodes).forEach { line, node in
            node.fillColor = DesignBook.shared.color(chart: chart, key: .line(line.colorKey))
        }
    }
}
