//
//  ChartGuideNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGuideNode: IChartNode {
    func update(edge: ChartRange, duration: TimeInterval)
}

final class ChartGuideNode: ChartNode, IChartGuideNode {
    private enum VerticalActiveGuide {
        case primary
        case secondary
    }
    
    private let primaryGuides: [ChartVerticalStepNode]
    private let secondaryGuides: [ChartVerticalStepNode]
    
    private let numberOfVerticalGuides = 6
    private var activeGuide: VerticalActiveGuide? = .primary
    private var lastEdge: ChartRange?
    
    init(chart: Chart, config: ChartConfig, alignment: NSTextAlignment, formattingProvider: IFormattingProvider) {
        primaryGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartVerticalStepNode(alignment: alignment) }
        secondaryGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartVerticalStepNode(alignment: alignment) }

        super.init(frame: .zero)
        
        primaryGuides.forEach { node in
            node.alpha = 1.0
            addSubview(node)
        }
        
        secondaryGuides.forEach { node in
            node.alpha = 0
            addSubview(node)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(edge: ChartRange, duration: TimeInterval) {
        guard let activeGuide = activeGuide else { return }
        let guidesPair = obtainGuides()
        
        guard edge != lastEdge else { return }
        defer { lastEdge = edge }
        
        func _layout(guides: [ChartVerticalStepNode],
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
                
                let guide = guides[step]
                guide.frame = CGRect(x: 0, y: currentY, width: bounds.width, height: 20)
                guide.value = (step > 0 && value == 0 ? String() : String(describing: value))
                guide.color = color
                guide.alpha = alpha
            }
        }
        
        if let lastEdge = lastEdge, !isMinorEdgeChange(fromEdge: lastEdge, toEdge: edge) {
            let scalingCoef = lastEdge.distance / edge.distance
            let startDiff = edge.start - lastEdge.start
            
            let relativeFromPosition = (startDiff / lastEdge.distance) * bounds.height
            let adjustFromPosition = -relativeFromPosition * (1 + scalingCoef)
            
            let relativeHeight = (lastEdge.distance / edge.distance) // size.height * (1.0 / scalingCoef)
            let sourceToHeight = bounds.height / relativeHeight
            let destinationToHeight = bounds.height
            
            _layout(
                guides: guidesPair.primary,
                usingEdge: lastEdge,
                startY: adjustFromPosition,
                height: bounds.height,
                alpha: 1.0
            )
            
            _layout(
                guides: guidesPair.secondary,
                usingEdge: edge,
                startY: relativeFromPosition,
                height: sourceToHeight,
                alpha: 0
            )
            
            self.activeGuide = nil
            UIView.animate(
                withDuration: (duration > 0 ? duration : 0.15),
                animations: { [unowned self] in
                    _layout(
                        guides: guidesPair.primary,
                        usingEdge: lastEdge,
                        startY: adjustFromPosition,
                        height: destinationToHeight * scalingCoef,
                        alpha: 0
                    )
                    
                    _layout(
                        guides: guidesPair.secondary,
                        usingEdge: edge,
                        startY: 0,
                        height: destinationToHeight,
                        alpha: 1.0
                    )
                },
                completion: { [unowned self] _ in
                    switch activeGuide {
                    case .primary: self.activeGuide = .secondary
                    case .secondary: self.activeGuide = .primary
                    }
                }
            )
        }
        else {
            _layout(
                guides: guidesPair.primary,
                usingEdge: edge,
                startY: 0,
                height: bounds.height,
                alpha: 1.0
            )
            
            guidesPair.primary.forEach { $0.alpha = 1.0 }
            guidesPair.secondary.forEach { $0.alpha = 0 }
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        primaryGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        primaryGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartPointerStepperLineStroke) }
        secondaryGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        secondaryGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartPointerStepperLineStroke) }
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
    
    private func obtainGuides() -> (primary: [ChartVerticalStepNode], secondary: [ChartVerticalStepNode]) {
        switch activeGuide {
        case .none: return ([], [])
        case .some(.primary): return (primaryGuides, secondaryGuides)
        case .some(.secondary): return (secondaryGuides, primaryGuides)
        }
    }
}
