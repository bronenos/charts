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
    private let dimmingNode = ChartFigureNode(figure: .filledPaths)

    override init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, enableControls: Bool) {
        super.init(
            chart: chart,
            config: config,
            formattingProvider: formattingProvider,
            enableControls: enableControls
        )
        
        configure(figure: .filledPaths) { index, node, line in
            node.fillColor = line.color
            node.layer.zPosition = -CGFloat(index)
        }
        
        dimmingNode.fillColor = DesignBook.shared.color(.chartPointerDimming)
        dimmingNode.alpha = 0
        dimmingNode.isHidden = !enableControls
        dimmingNode.isUserInteractionEnabled = false
        figuresContainer.addSubview(dimmingNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var numberOfSteps: Int {
        return chart.axis.count
    }
    
    override func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        let newVisible = newConfig.lines.map { $0.visible }
        let oldVisible = oldConfig.lines.map { $0.visible }
        return (newVisible != oldVisible)
    }
    
    override func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                                   duration: TimeInterval,
                                                   completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        return ChartBarPointsOperation(
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
                            color: line.color
                        )
                    }
                ),
                options: [],
                duration: duration *  2
            )
        }
        else {
            container?.adjustPointer(
                pointing: nil,
                content: nil,
                options: [],
                duration: duration *  2
            )
        }
        
        if enableControls {
            layout(duration: 0)
            
            let dimmingAlpha = CGFloat(config.pointer == nil ? 0 : 1.0)
            if dimmingNode.alpha != dimmingAlpha {
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.dimmingNode.alpha = dimmingAlpha
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutDimmingNodes()
    }
    
    private func layoutDimmingNodes() {
        guard let pointer = config.pointer else { return }
        guard let index = calculateIndex(pointer: pointer, rounder: floor) else { return }
        guard let firstNode = orderedNodes.first else { return }
        
        let stepX = bounds.width / CGFloat(numberOfSteps)
        let baseX = CGFloat(index) * stepX
        
        let leftX = firstNode.convertOriginalToEffective(x: baseX)
        let leftFrame = CGRect(x: 0,y: 0, width: leftX, height: bounds.height)
        
        let rightX = firstNode.convertOriginalToEffective(x: baseX + stepX)
        let rightFrame = CGRect(x: rightX, y: 0, width: bounds.width - rightX, height: bounds.height)
        
        dimmingNode.bezierPaths = [
            UIBezierPath(rect: leftFrame),
            UIBezierPath(rect: rightFrame)
        ]
    }
}
