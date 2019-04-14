//
//  ChartBarGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 09/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartBarGraphNode: IChartGraphNode {
}

class ChartBarGraphNode: ChartGraphNode, IChartBarGraphNode {
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
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        let newVisible = newConfig.lines.map { $0.visible }
        let oldVisible = oldConfig.lines.map { $0.visible }
        return (newVisible != oldVisible)
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   date: Date,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartBarPointsOperation(
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
        return ChartBarEyesOperation(
            chart: chart,
            config: config,
            meta: meta,
            bounds: bounds,
            context: context,
            completion: completion
        )
    }
    
    override func updateChart(points: [String: [CGPoint]]) {
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
    
    override func updateEyes(_ eyes: [ChartGraphEye], edges: [ChartRange], duration: TimeInterval) {
        super.updateEyes(eyes, edges: edges, duration: duration)
    }
    
    override func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        container?.adjustGuides(
            left: edges.first ?? .empty,
            right: nil,
            duration: duration
        )
    }
    
    override func updatePointer(meta: ChartSliceMeta, totalEdges: [ChartRange]) {
        container?.adjustPointer(
            chart: chart,
            config: config,
            meta: meta,
            edges: [],
            options: [.line]
        )
    }
}
