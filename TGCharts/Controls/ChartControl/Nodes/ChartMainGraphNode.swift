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
    var pointerLineNode: IChartFigureNode { get }
    var pointerCloudNode: IChartPointerCloudNode { get }
}

final class ChartMainGraphNode: ChartGraphNode, IChartMainGraphNode {
    let pointerLineNode: IChartFigureNode
    let pointerCloudNode: IChartPointerCloudNode

    init(tag: String, width: CGFloat, formattingProvider: IFormattingProvider) {
        pointerLineNode = ChartFigureNode(tag: "pointer-line")
        pointerCloudNode = ChartPointerCloudNode(tag: "pointer-cloud", formattingProvider: formattingProvider)
        
        super.init(tag: tag, width: width)
        
        addChild(node: pointerLineNode)
        addChild(node: pointerCloudNode)
    }
    
    override func update(meta: ChartSliceMeta, edge: ChartRange, lineMetas: [ChartGraphNode.LineMeta]) {
        super.update(meta: meta, edge: edge, lineMetas: lineMetas)
        placeHorizontalPointer(meta: meta, edge: edge, lineMetas: lineMetas)
        placeVerticalIndices(meta: meta, edge: edge, lineMetas: lineMetas)
    }
    
    private func placeHorizontalPointer(meta: ChartSliceMeta, edge: ChartRange, lineMetas: [ChartGraphNode.LineMeta]) {
        guard let pointer = config.pointer else { return }
        guard let firstRenderedIndex = meta.renderedIndices.first else { return }
        
        let offset = Int(round((meta.margins.left + size.width * pointer) / meta.stepX))
        let index = firstRenderedIndex + offset
        
        var commonPositionX = CGFloat(0)
        var commonPositionY = CGFloat.infinity
        
        lineMetas.forEach { lineMeta in
            let outerPointNode = ChartFigureNode(tag: "pointer-point")
            outerPointNode.figure = .separatePoints
            outerPointNode.frame = CGRect(origin: lineMeta.points[offset], size: .zero)
            outerPointNode.points = [.zero]
            outerPointNode.width = 8
            outerPointNode.color = lineMeta.line.color
            outerPointNode.isInteractable = false
            addChild(node: outerPointNode)
            
            let innerPointNode = ChartFigureNode(tag: "pointer-point")
            innerPointNode.figure = .separatePoints
            innerPointNode.frame = CGRect(origin: lineMeta.points[offset], size: .zero)
            innerPointNode.points = [.zero]
            innerPointNode.width = 5
            innerPointNode.color = DesignBook.shared.color(.primaryBackground)
            innerPointNode.isInteractable = false
            addChild(node: innerPointNode)
            
            commonPositionX = lineMeta.points[offset].x
            commonPositionY = min(commonPositionY, lineMeta.points[offset].y)
        }
        
        pointerLineNode.frame = CGRect(x: commonPositionX, y: commonPositionY, width: 1, height: size.height - commonPositionY)
        pointerLineNode.figure = .joinedLines
        pointerLineNode.points = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: size.height - commonPositionY)]
        pointerLineNode.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        addChild(node: pointerLineNode, target: .back)
        
        let pointerCloudOverplace = CGFloat(10)
        let pointerCloudWidth = CGFloat(90)
        let pointerCloudLeftX = (size.width + pointerCloudOverplace * 2 - pointerCloudWidth) * pointer - pointerCloudOverplace
        pointerCloudNode.frame = CGRect(x: pointerCloudLeftX, y: 0, width: pointerCloudWidth, height: size.height)
        pointerCloudNode.setDate(chart.axis[index].date, lines: lineMetas.map { $0.line }, index: index)
        addChild(node: pointerCloudNode)
    }
    
    private func placeVerticalIndices(meta: ChartSliceMeta, edge: ChartRange, lineMetas: [ChartGraphNode.LineMeta]) {
        let numberOfSteps = 6
        let stepY = size.height / CGFloat(numberOfSteps)
        let stepValue = edge.distance / CGFloat(numberOfSteps)
        
        (0 ..< numberOfSteps).forEach { step in
            let value = Int(edge.start + CGFloat(step) * stepValue)
            let currentY = CGFloat(step) * stepY
            let color = DesignBook.shared.color(step == 0 ? .chartPointerFocusedLineStroke : .chartPointerStepperLineStroke)

            let stepNode = ChartVerticalStepNode(tag: "graph-step")
            stepNode.frame = CGRect(x: 0, y: currentY, width: size.width, height: 20)
            stepNode.value = String(describing: value)
            stepNode.color = color
            addChild(node: stepNode, target: .back)
        }
    }
}
