//
//  ChartMainGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 20/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartMainGraphNode: IChartGraphNode {
}

final class ChartMainGraphNode: ChartGraphNode, IChartMainGraphNode {
    private let pointerCloudNode: IChartPointerCloudNode
    
    private var verticalValueNodes = [IChartVerticalStepNode]()
    private var verticalPostValueNodes = [IChartVerticalStepNode]()
    private var verticalLineNodes = [IChartVerticalStepNode]()
    private var verticalPostLineNodes = [IChartVerticalStepNode]()
    private var temporaryNodes = [IChartNode]()

    init(tag: String, width: CGFloat, formattingProvider: IFormattingProvider) {
        pointerCloudNode = ChartPointerCloudNode(tag: "pointer-cloud", formattingProvider: formattingProvider)
        
        super.init(tag: tag, width: width, cachable: false)
        
        addChild(node: pointerCloudNode, target: .front)
    }
    
    override func update(meta: ChartSliceMeta, edge: ChartRange, lineMetas: [ChartGraphNode.LineMeta]) {
        super.update(meta: meta, edge: edge, lineMetas: lineMetas)
        placeHorizontalPointer(meta: meta, edge: edge, lineMetas: lineMetas)
        placeVerticalIndices(meta: meta, edge: edge, lineMetas: lineMetas)
    }
    
    private func placeHorizontalPointer(meta: ChartSliceMeta, edge: ChartRange, lineMetas: [ChartGraphNode.LineMeta]) {
        temporaryNodes.forEach { $0.removeFromParent() }
        temporaryNodes.removeAll()
        
        guard let pointer = config.pointer else {
            pointerCloudNode.removeFromParent()
            return
        }
        
        guard let firstRenderedIndex = meta.renderedIndices.first else {
            pointerCloudNode.removeFromParent()
            return
        }
        
        let offset = Int(round((meta.margins.left + size.width * pointer) / meta.stepX))
        let index = firstRenderedIndex + offset
        
        var commonPositionX = CGFloat(0)
        var commonPositionY = CGFloat.infinity
        
        lineMetas.forEach { lineMeta in
            let outerPointNode = ChartFigureNode(tag: "pointer-point", cachable: false)
            outerPointNode.figure = .separatePoints
            outerPointNode.frame = CGRect(origin: lineMeta.points[offset], size: .zero)
            outerPointNode.points = [.zero]
            outerPointNode.width = 8
            outerPointNode.color = lineMeta.line.color
            outerPointNode.isInteractable = false
            addChild(node: outerPointNode)
            temporaryNodes.append(outerPointNode)

            let innerPointNode = ChartFigureNode(tag: "pointer-point", cachable: false)
            innerPointNode.figure = .separatePoints
            innerPointNode.frame = CGRect(origin: lineMeta.points[offset], size: .zero)
            innerPointNode.points = [.zero]
            innerPointNode.width = 5
            innerPointNode.color = DesignBook.shared.color(.primaryBackground)
            innerPointNode.isInteractable = false
            addChild(node: innerPointNode)
            temporaryNodes.append(innerPointNode)

            commonPositionX = lineMeta.points[offset].x
            commonPositionY = min(commonPositionY, lineMeta.points[offset].y)
        }
        
        let pointerLineNode = ChartFigureNode(tag: "pointer-line", cachable: false)
        pointerLineNode.frame = CGRect(x: commonPositionX, y: commonPositionY, width: 1, height: size.height - commonPositionY)
        pointerLineNode.figure = .joinedLines
        pointerLineNode.points = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: size.height - commonPositionY)]
        pointerLineNode.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        addChild(node: pointerLineNode, target: .back)
        temporaryNodes.append(pointerLineNode)

        pointerCloudNode.setDate(chart.axis[index].date, lines: lineMetas.map { $0.line }, index: index)
        let pointerCloudOverplace = CGFloat(10)
        let pointerCloudWidth = pointerCloudNode.calculateSize().width
        let pointerCloudLeftX = (size.width + pointerCloudOverplace * 2 - pointerCloudWidth) * pointer - pointerCloudOverplace
        pointerCloudNode.frame = CGRect(x: pointerCloudLeftX, y: 0, width: pointerCloudWidth, height: size.height)
        moveChild(node: pointerCloudNode, target: .front)
    }
    
    private func placeVerticalIndices(meta: ChartSliceMeta, edge: ChartRange, lineMetas: [ChartGraphNode.LineMeta]) {
        func _layout(valueNodes: inout [IChartVerticalStepNode],
                     lineNodes: inout [IChartVerticalStepNode],
                     usingEdge: ChartRange,
                     startY: CGFloat,
                     height: CGFloat,
                     alpha: CGFloat) {
            let numberOfSteps = 6
            let stepY = height / CGFloat(numberOfSteps)
            let stepValue = usingEdge.distance / CGFloat(numberOfSteps)
            
            (0 ..< numberOfSteps).forEach { step in
                let value = Int(usingEdge.start + CGFloat(step) * stepValue)
                let currentY = startY + CGFloat(step) * stepY
                let color = DesignBook.shared.color(step == 0 ? .chartPointerFocusedLineStroke : .chartPointerStepperLineStroke)
                
                if step >= valueNodes.count {
                    let valueNode = ChartVerticalStepNode(tag: "graph-step", step: .value)
                    addChild(node: valueNode, target: .front)
                    valueNodes.append(valueNode)
                    
                    let lineNode = ChartVerticalStepNode(tag: "graph-step", step: .line)
                    addChild(node: lineNode, target: .back)
                    lineNodes.append(lineNode)
                }
                
                let valueNode = valueNodes[step]
                valueNode.frame = CGRect(x: 0, y: currentY, width: size.width, height: 20)
                valueNode.value = (step > 0 && value == 0 ? String() : String(describing: value))
                valueNode.color = color
                valueNode.alpha = alpha
                
                let lineNode = lineNodes[step]
                lineNode.frame = CGRect(x: 0, y: currentY, width: size.width, height: 20)
                lineNode.value = String(describing: value)
                lineNode.color = color
                lineNode.alpha = alpha
            }
        }
        
        if let progress = overrideProgress, let fromEdge = overrideFromEdge, let toEdge = overrideToEdge {
            let scalingCoef = fromEdge.distance / edge.distance
            let startDiff = edge.start - fromEdge.start

            let relativeFromPosition = (startDiff / fromEdge.distance) * size.height
            let adjustFromPosition = -relativeFromPosition * (1 + scalingCoef)
            
            _layout(
                valueNodes: &verticalValueNodes,
                lineNodes: &verticalLineNodes,
                usingEdge: fromEdge,
                startY: adjustFromPosition,
                height: size.height * scalingCoef,
                alpha: 1.0 - progress
            )
            
            let relativeHeight = (fromEdge.distance / toEdge.distance) // size.height * (1.0 / scalingCoef)
            let adjustToPosition = relativeFromPosition * (1.0 - progress) // * (scalingCoef - 1)
            let sourceToHeight = size.height / relativeHeight
            let destinationToHeight = size.height
            let resultToHeight = destinationToHeight + (sourceToHeight - destinationToHeight) * (1.0 - progress)
            
            _layout(
                valueNodes: &verticalPostValueNodes,
                lineNodes: &verticalPostLineNodes,
                usingEdge: toEdge,
                startY: adjustToPosition,
                height: resultToHeight,
                alpha: progress
            )
        }
        else {
            _layout(
                valueNodes: &verticalValueNodes,
                lineNodes: &verticalLineNodes,
                usingEdge: edge,
                startY: 0,
                height: size.height,
                alpha: 1.0
            )
            
            verticalPostValueNodes.forEach { $0.alpha = 0 }
            verticalPostLineNodes.forEach { $0.alpha = 0 }
        }
    }
}
