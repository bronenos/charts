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
    private let pointerLineNode = ChartNode()
    
    override init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        super.init(chart: chart, config: config, formattingProvider: formattingProvider)
        
        pointerLineNode.isHidden = true
        addSubview(pointerLineNode)
        
        configure(figure: .filledPaths) { index, node, line in
            node.fillColor = line.color
            node.layer.zPosition = -CGFloat(index)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func placeAreas(meta: ChartSliceMeta, offset: CGFloat, points: [String: [CGPoint]], duration: TimeInterval) {
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
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        let newVisible = newConfig.lines.map { $0.visible }
        let oldVisible = oldConfig.lines.map { $0.visible }
        return (newVisible != oldVisible)
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   date: Date,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartAreaPointsOperation(
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
        return ChartAreaFocusOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: context,
            completion: completion
        )
    }
    
    override func updateChart(_ chart: Chart, meta: ChartSliceMeta, edges: [ChartRange], duration: TimeInterval) {
        placeAreas(
            meta: meta,
            offset: meta.totalWidth * config.range.start,
            points: cachedPointsResult?.points ?? [:],
            duration: duration
        )
    }
    
    override func updateFocus(_ focuses: [UIEdgeInsets], edges: [ChartRange], duration: TimeInterval) {
        super.updateFocus(focuses, edges: edges, duration: duration)
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            left: edges.first ?? ChartRange(start: 0, end: 0),
            right: nil,
            duration: duration
        )
    }
    
    override func updatePointer(meta: ChartSliceMeta) {
        guard let edge = cachedPointsResult?.context.totalEdges.first else { return }
        
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: chart.lines.map { _ in edge },
            options: [.line]
        )
    }
}