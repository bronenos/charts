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
    private var verticalLineNodes = [IChartVerticalStepNode]()
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
        let numberOfSteps = 6
        let stepY = size.height / CGFloat(numberOfSteps)
        let stepValue = edge.distance / CGFloat(numberOfSteps)
        
        (0 ..< numberOfSteps).forEach { step in
            let value = Int(edge.start + CGFloat(step) * stepValue)
            let currentY = CGFloat(step) * stepY
            let color = DesignBook.shared.color(step == 0 ? .chartPointerFocusedLineStroke : .chartPointerStepperLineStroke)

            if step >= verticalValueNodes.count {
                let valueNode = ChartVerticalStepNode(tag: "graph-step", step: .value)
                addChild(node: valueNode, target: .front)
                verticalValueNodes.append(valueNode)
                
                let lineNode = ChartVerticalStepNode(tag: "graph-step", step: .line)
                addChild(node: lineNode, target: .back)
                verticalLineNodes.append(lineNode)
            }
            
            let valueNode = verticalValueNodes[step]
            valueNode.frame = CGRect(x: 0, y: currentY, width: size.width, height: 20)
            valueNode.value = String(describing: value)
            valueNode.color = color
            
            let lineNode = verticalLineNodes[step]
            lineNode.frame = CGRect(x: 0, y: currentY, width: size.width, height: 20)
            lineNode.value = String(describing: value)
            lineNode.color = color
        }
    }
}
