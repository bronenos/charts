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
        
        if let pointer = config.pointer, let firstRenderedIndex = meta.renderedIndices.first {
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
                innerPointNode.color = DesignBook.shared.resolve(colorAlias: .elementRegularBackground)
                innerPointNode.isInteractable = false
                addChild(node: innerPointNode)
                
                commonPositionX = lineMeta.points[offset].x
                commonPositionY = min(commonPositionY, lineMeta.points[offset].y)
            }
            
            pointerLineNode.frame = CGRect(x: commonPositionX, y: commonPositionY, width: 1, height: size.height - commonPositionY)
            pointerLineNode.figure = .joinedLines
            pointerLineNode.points = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: size.height - commonPositionY)]
            pointerLineNode.color = DesignBook.shared.resolve(colorAlias: .chartGridBackground)
            addChild(node: pointerLineNode, target: .back)
            
            let pointerCloudOverplace = CGFloat(10)
            let pointerCloudWidth = CGFloat(90)
            let pointerCloudLeftX = (size.width + pointerCloudOverplace * 2 - pointerCloudWidth) * pointer - pointerCloudOverplace
            pointerCloudNode.frame = CGRect(x: pointerCloudLeftX, y: 0, width: pointerCloudWidth, height: size.height)
            pointerCloudNode.setDate(chart.axis[index].date, lines: lineMetas.map { $0.line }, index: index)
            addChild(node: pointerCloudNode)
        }
    }
}
