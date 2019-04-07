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
    private enum VerticalActiveGuide {
        case primary
        case secondary
    }
    
    private let verticalValuesContainer = ChartView()
    private let verticalUnderlineContainer = ChartView()
    private let verticalValueGuides: [ChartVerticalStepNode]
    private let verticalUnderlineGuides: [ChartVerticalStepNode]
    private let verticalPostValueGuides: [ChartVerticalStepNode]
    private let verticalPostUnderlineGuides: [ChartVerticalStepNode]
    private let pointerCloudNode: ChartPointerCloudNode
    private let pointerDotNodes: [ChartFigureNode]
    private let pointerLineNode: ChartNode
    
    private let numberOfVerticalGuides = 6
    private var verticalActiveGuide: VerticalActiveGuide? = .primary
    private var lastEdge: ChartRange?
    
    init(chart: Chart, config: ChartConfig, width: CGFloat, formattingProvider: IFormattingProvider) {
        verticalValueGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartVerticalStepNode(mode: .value) }
        verticalUnderlineGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartVerticalStepNode(mode: .underline) }
        verticalPostValueGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartVerticalStepNode(mode: .value) }
        verticalPostUnderlineGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartVerticalStepNode(mode: .underline) }
        pointerCloudNode = ChartPointerCloudNode(formattingProvider: formattingProvider)
        pointerDotNodes = chart.lines.indices.map { _ in ChartFigureNode(figure: .nestedBezierPaths) }
        pointerLineNode = ChartNode()
        
        super.init(chart: chart, config: config, width: width)
        
        verticalValuesContainer.clipsToBounds = true
        verticalValuesContainer.isUserInteractionEnabled = false
        addSubview(verticalValuesContainer)
        
        verticalUnderlineContainer.clipsToBounds = true
        verticalUnderlineContainer.isUserInteractionEnabled = false
        insertSubview(verticalUnderlineContainer, at: 0)
        
        linesContainer.tag = ChartControlTag.mainGraph.rawValue
        
        verticalValueGuides.forEach { node in
            node.alpha = 1.0
            verticalValuesContainer.addSubview(node)
        }
        
        verticalUnderlineGuides.forEach { node in
            node.alpha = 1.0
            verticalUnderlineContainer.addSubview(node)
        }
        
        verticalPostValueGuides.forEach { node in
            node.alpha = 0
            verticalValuesContainer.addSubview(node)
        }

        verticalPostUnderlineGuides.forEach { node in
            node.alpha = 0
            verticalUnderlineContainer.addSubview(node)
        }
        
        addSubview(pointerCloudNode)
        pointerDotNodes.forEach(linesContainer.addSubview)
        insertSubview(pointerLineNode, at: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override func update(chart: Chart, meta: ChartSliceMeta, edge: ChartRange) {
        super.update(chart: chart, meta: meta, edge: edge)
        placeHorizontalPointer(meta: meta, edge: edge)
        placeVerticalIndices(meta: meta, edge: edge)
    }
    
    override func updateDesign() {
        super.updateDesign()
        verticalValueGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        verticalUnderlineGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        verticalValueGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartPointerStepperLineStroke) }
        verticalUnderlineGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartPointerStepperLineStroke) }
        verticalPostValueGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        verticalPostUnderlineGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        verticalPostValueGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartPointerStepperLineStroke) }
        verticalPostUnderlineGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartPointerStepperLineStroke) }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        verticalValuesContainer.frame = bounds
        verticalUnderlineContainer.frame = bounds
    }
    
    private func placeHorizontalPointer(meta: ChartSliceMeta, edge: ChartRange) {
        if let pointer = config.pointer {
            let startIndex = meta.visibleIndices.startIndex
            let endIndex = meta.visibleIndices.endIndex
            let pointedIndex = startIndex + Int(CGFloat(endIndex - startIndex - 1) * pointer)
            
            let offset = meta.totalWidth * config.range.start
            let x = -offset + meta.stepX * CGFloat(pointedIndex)
            var lowestY = CGFloat(0)
            
            zip(pointerDotNodes, chart.lines).forEach { node, line in
                let value = line.values[pointedIndex]
                let y = calculateY(value: value, edge: edge)
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
            }
            
            pointerLineNode.frame = CGRect(
                x: max(0, min(bounds.width - 1, x)),
                y: 0,
                width: 1,
                height: lowestY
            )
            
            pointerLineNode.backgroundColor = DesignBook.shared.color(.chartPointerFocusedLineStroke)
            
            let visibleLines = chart.visibleLines(config: config, addingKeys: [])
            pointerCloudNode.setDate(chart.axis[pointedIndex].date, lines: visibleLines, index: pointedIndex)
            
            let pointerCloudOffscreen = CGFloat(10)
            let pointerCloudWidth = pointerCloudNode.sizeThatFits(.zero).width
            let pointerCloudLeftX = (bounds.size.width + pointerCloudOffscreen * 2 - pointerCloudWidth) * pointer - pointerCloudOffscreen
            let pointerNormalizedLeftX = pointerCloudLeftX // max(0, min(bounds.width - pointerCloudWidth, pointerCloudLeftX))
            pointerCloudNode.frame = CGRect(x: pointerNormalizedLeftX, y: 0, width: pointerCloudWidth, height: bounds.height)
            bringSubviewToFront(pointerCloudNode)
            
            obtainPointerControls(onlyVisible: true).forEach { $0.alpha = 1.0 }
        }
        else {
            obtainPointerControls(onlyVisible: false).forEach { $0.alpha = 0 }
        }
    }
    
    private func placeVerticalIndices(meta: ChartSliceMeta, edge: ChartRange) {
        guard let activeGuide = verticalActiveGuide else { return }
        
        guard edge != lastEdge else { return }
        defer { lastEdge = edge }
        
        func _layout(valueNodes: [ChartVerticalStepNode],
                     underlineNodes: [ChartVerticalStepNode],
                     usingEdge: ChartRange,
                     startY: CGFloat,
                     height: CGFloat,
                     alpha: CGFloat) {
            let stepY = height / CGFloat(numberOfVerticalGuides)
            let stepValue = usingEdge.distance / CGFloat(numberOfVerticalGuides)
            
            (0 ..< numberOfVerticalGuides).forEach { step in
                let height = CGFloat(20)
                let value = Int(usingEdge.start + CGFloat(step) * stepValue)
                let currentY = bounds.height - (startY + CGFloat(step) * stepY) - height
                let color = DesignBook.shared.color(step == 0 ? .chartPointerFocusedLineStroke : .chartPointerStepperLineStroke)
                
                let valueNode = valueNodes[step]
                valueNode.frame = CGRect(x: 0, y: currentY, width: bounds.width, height: 20)
                valueNode.value = (step > 0 && value == 0 ? String() : String(describing: value))
                valueNode.color = color
                valueNode.alpha = alpha
                
                let underlineNode = underlineNodes[step]
                underlineNode.frame = CGRect(x: 0, y: currentY, width: bounds.width, height: 20)
                underlineNode.color = color
                underlineNode.alpha = alpha
            }
        }
        
        if let lastEdge = lastEdge, !isMinorEdgeChange(fromEdge: lastEdge, toEdge: edge) {
            let currentPairs = obtainCurrentPairs()
            let otherPairs = obtainOtherPairs()

            let scalingCoef = lastEdge.distance / edge.distance
            let startDiff = edge.start - lastEdge.start
            
            let relativeFromPosition = (startDiff / lastEdge.distance) * bounds.height
            let adjustFromPosition = -relativeFromPosition * (1 + scalingCoef)
            
            let relativeHeight = (lastEdge.distance / edge.distance) // size.height * (1.0 / scalingCoef)
            let sourceToHeight = bounds.height / relativeHeight
            let destinationToHeight = bounds.height
            
            _layout(
                valueNodes: currentPairs?.values ?? [],
                underlineNodes: currentPairs?.underlines ?? [],
                usingEdge: lastEdge,
                startY: adjustFromPosition,
                height: destinationToHeight * scalingCoef,
                alpha: 0
            )
            
            _layout(
                valueNodes: otherPairs?.values ?? [],
                underlineNodes: otherPairs?.underlines ?? [],
                usingEdge: edge,
                startY: relativeFromPosition,
                height: sourceToHeight,
                alpha: 1.0
            )
            
            verticalActiveGuide = nil
            UIView.animate(
                withDuration: 0.15,
                animations: { [unowned self] in
                    _layout(
                        valueNodes: currentPairs?.values ?? [],
                        underlineNodes: currentPairs?.underlines ?? [],
                        usingEdge: lastEdge,
                        startY: adjustFromPosition,
                        height: destinationToHeight * scalingCoef,
                        alpha: 0
                    )
                    
                    _layout(
                        valueNodes: otherPairs?.values ?? [],
                        underlineNodes: otherPairs?.underlines ?? [],
                        usingEdge: edge,
                        startY: 0,
                        height: destinationToHeight,
                        alpha: 1.0
                    )
                },
                completion: { [unowned self] _ in
                    switch activeGuide {
                    case .primary: self.verticalActiveGuide = .secondary
                    case .secondary: self.verticalActiveGuide = .primary
                    }
                }
            )
        }
        else {
            _layout(
                valueNodes: verticalValueGuides,
                underlineNodes: verticalUnderlineGuides,
                usingEdge: edge,
                startY: 0,
                height: bounds.height,
                alpha: 1.0
            )
            
            let currentPairs = obtainCurrentPairs()
            currentPairs?.values.forEach { $0.alpha = 1.0 }
            currentPairs?.underlines.forEach { $0.alpha = 1.0 }
            
            let otherPairs = obtainOtherPairs()
            otherPairs?.values.forEach { $0.alpha = 0 }
            otherPairs?.underlines.forEach { $0.alpha = 0 }
        }
    }
    
    private func isMinorEdgeChange(fromEdge: ChartRange, toEdge: ChartRange) -> Bool {
        if !(fromEdge.distance > 0 && toEdge.distance > 0) {
            return true
        }
        
        let growth = abs(fromEdge.distance - toEdge.distance)
        if (growth / max(fromEdge.distance, toEdge.distance)) > 0.1 {
            return false
        }
        else {
            return true
        }
    }
    
    private func obtainPointerControls(onlyVisible: Bool) -> [UIView] {
        return [pointerCloudNode, pointerLineNode] + obtainPointerDots(onlyVisible: onlyVisible)
    }
    
    private func obtainPointerDots(onlyVisible: Bool) -> [UIView] {
        return zip(pointerDotNodes, config.lines).compactMap { (dotNode, lineConfig) in
            guard !onlyVisible || lineConfig.visible else { return nil }
            return dotNode
        }
    }
    
    private func obtainCurrentPairs() -> (values: [ChartVerticalStepNode], underlines: [ChartVerticalStepNode])? {
        switch verticalActiveGuide {
        case .none: return nil
        case .some(.primary): return (verticalValueGuides, verticalUnderlineGuides)
        case .some(.secondary): return (verticalPostValueGuides, verticalPostUnderlineGuides)
        }
    }
    
    private func obtainOtherPairs() -> (values: [ChartVerticalStepNode], underlines: [ChartVerticalStepNode])? {
        switch verticalActiveGuide {
        case .none: return nil
        case .some(.primary): return (verticalPostValueGuides, verticalPostUnderlineGuides)
        case .some(.secondary): return (verticalValueGuides, verticalUnderlineGuides)
        }
    }
}
