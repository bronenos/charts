//
//  ChartPointerNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartPointerOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    
    static let line = ChartPointerOptions(rawValue: 1 << 0)
    static let dots = ChartPointerOptions(rawValue: 1 << 1)
}

protocol IChartPointerNode: IChartNode {
    func update(chart: Chart, config: ChartConfig, meta: ChartSliceMeta, edges: [ChartRange], options: ChartPointerOptions)
}

final class ChartPointerNode: ChartNode, IChartPointerNode {
    private let clippedContainer = ChartNode()
    
    private let pointerCloudNode: ChartPointerCloudNode
    private let pointerDotNodes: [ChartFigureNode]
    private let pointerLineNode: ChartNode
    
    init(chart: Chart, formattingProvider: IFormattingProvider) {
        pointerCloudNode = ChartPointerCloudNode(formattingProvider: formattingProvider)
        pointerDotNodes = chart.lines.indices.map { _ in ChartFigureNode(figure: .nestedBezierPaths) }
        pointerLineNode = ChartNode()
        
        super.init(frame: .zero)
        
        addSubview(pointerLineNode)
        
        clippedContainer.clipsToBounds = true
        pointerDotNodes.forEach(clippedContainer.addSubview)
        addSubview(clippedContainer)
        
        addSubview(pointerCloudNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(chart: Chart, config: ChartConfig, meta: ChartSliceMeta, edges: [ChartRange], options: ChartPointerOptions) {
        if let pointer = config.pointer {
            let startIndex = meta.visibleIndices.startIndex
            let endIndex = meta.visibleIndices.endIndex
            let pointedIndex = startIndex + Int(CGFloat(endIndex - startIndex) * pointer)
            
            let offset = meta.totalWidth * config.range.start
            let x = -offset + meta.stepX * CGFloat(pointedIndex)
            var lowestY = CGFloat(0)
            
            for index in chart.lines.indices {
                let line = chart.lines[index]
                let edge = edges[index]
                let node = pointerDotNodes[index]
                
                let value = line.values[pointedIndex]
                let y = bounds.calculateY(value: value, edge: edge)
                lowestY = max(lowestY, y)
                
                let path = UIBezierPath(
                    arcCenter: .zero,
                    radius: 3,
                    startAngle: 0,
                    endAngle: .pi * 2,
                    clockwise: true
                )
                
                node.frame = CGRect(x: x, y: y, width: 1, height: 1)
                node.strokeColor = line.color
                node.fillColor = DesignBook.shared.color(.primaryBackground)
                node.bezierPaths = [path]
                node.width = 2
                node.isHidden = !options.contains(.dots)
            }
            
            let pointerLineX = max(0, min(bounds.width - 1, x))
            pointerLineNode.frame = CGRect(x: pointerLineX, y: 0, width: 1, height: bounds.height)
            pointerLineNode.backgroundColor = DesignBook.shared.color(.chartPointerFocusedLineStroke)
            pointerLineNode.isHidden = !options.contains(.line)

            let visibleLines = chart.visibleLines(config: config, addingKeys: [])
            pointerCloudNode.setDate(chart.axis[pointedIndex].date, lines: visibleLines, index: pointedIndex)
            
            let pointerCloudOffscreen = CGFloat(10)
            let pointerCloudWidth = pointerCloudNode.sizeThatFits(.zero).width
            let pointerCloudLeftX = (bounds.size.width + pointerCloudOffscreen * 2 - pointerCloudWidth) * pointer - pointerCloudOffscreen
            let pointerNormalizedLeftX = pointerCloudLeftX // max(0, min(bounds.width - pointerCloudWidth, pointerCloudLeftX))
            pointerCloudNode.frame = CGRect(x: pointerNormalizedLeftX, y: 0, width: pointerCloudWidth, height: bounds.height)
            
            obtainPointerControls(config: config, onlyVisible: true).forEach { $0.alpha = 1.0 }
        }
        else {
            obtainPointerControls(config: config, onlyVisible: false).forEach { $0.alpha = 0 }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        clippedContainer.frame = bounds
    }
    
    private func obtainPointerControls(config: ChartConfig, onlyVisible: Bool) -> [UIView] {
        return [pointerCloudNode, pointerLineNode] + obtainPointerDots(config: config, onlyVisible: onlyVisible)
    }
    
    private func obtainPointerDots(config: ChartConfig, onlyVisible: Bool) -> [UIView] {
        return zip(pointerDotNodes, config.lines).compactMap { (dotNode, lineConfig) in
            guard !onlyVisible || lineConfig.visible else { return nil }
            return dotNode
        }
    }
}
