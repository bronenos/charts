//
//  ChartGuideControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGuideControl: IChartNode {
    func update(edge: ChartRange?, duration: TimeInterval)
}

final class ChartGuideControl: ChartNode, IChartGuideControl {
    private struct GuidesPair {
        let primary: [ChartGuideStepNode]
        let secondary: [ChartGuideStepNode]
    }
    
    private enum VerticalActiveGuide {
        case primary
        case secondary
    }
    
    private let formattingProvider: IFormattingProvider
    
    private let primaryGuides: [ChartGuideStepNode]
    private let secondaryGuides: [ChartGuideStepNode]
    
    private let numberOfVerticalGuides = 6
    private var activeGuide: VerticalActiveGuide? = .primary
    private var lastEdge: ChartRange?
    
    init(chart: Chart, config: ChartConfig, alignment: NSTextAlignment, formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        primaryGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartGuideStepNode(alignment: alignment) }
        secondaryGuides = (0 ..< numberOfVerticalGuides).map { _ in ChartGuideStepNode(alignment: alignment) }

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
    
    func update(edge: ChartRange?, duration: TimeInterval) {
        guard let activeGuide = activeGuide else { return }
        let guidesPair = obtainGuides()
        
        guard edge != lastEdge else { return }
        defer { lastEdge = edge }
        
        if let edge = edge {
            if let lastEdge = lastEdge, !isMinorEdgeChange(fromEdge: lastEdge, toEdge: edge) {
                exchangeGuides(
                    edge: edge,
                    lastEdge: lastEdge,
                    duration: duration
                )
            }
            else {
                adjustGuides(
                    edge: edge,
                    duration: duration
                )
            }
        }
        else {
            adjustGuides(
                edge: .empty,
                duration: duration
            )
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        primaryGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        primaryGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartGuidesLineStroke) }
        secondaryGuides.first?.color = DesignBook.shared.color(.chartPointerFocusedLineStroke)
        secondaryGuides.dropFirst().forEach { $0.color = DesignBook.shared.color(.chartGuidesLineStroke) }
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
    
    private func exchangeGuides(edge: ChartRange,
                                lastEdge: ChartRange,
                                duration: TimeInterval) {
        let guidesPair = obtainGuides()
        
        let scalingCoef = lastEdge.distance / edge.distance
        let startDiff = edge.start - lastEdge.start
        
        let relativeFromPosition = (startDiff / lastEdge.distance) * bounds.height
        let adjustFromPosition = -relativeFromPosition * (1 + scalingCoef)
        
        let relativeHeight = (lastEdge.distance / edge.distance) // size.height * (1.0 / scalingCoef)
        let sourceToHeight = bounds.height / relativeHeight
        let destinationToHeight = bounds.height
        
        layoutGuides(
            guides: guidesPair.primary,
            usingEdge: lastEdge,
            startY: 0,
            height: bounds.height,
            alpha: 1.0
        )
        
        layoutGuides(
            guides: guidesPair.secondary,
            usingEdge: edge,
            startY: relativeFromPosition,
            height: sourceToHeight,
            alpha: 0
        )
        
        let currentGuide = activeGuide
        activeGuide = nil
        
        func _animations() {
            layoutGuides(
                guides: guidesPair.primary,
                usingEdge: lastEdge,
                startY: adjustFromPosition,
                height: destinationToHeight * scalingCoef,
                alpha: 0
            )
            
            layoutGuides(
                guides: guidesPair.secondary,
                usingEdge: edge,
                startY: 0,
                height: destinationToHeight,
                alpha: 1.0
            )
        }
        
        func _completion() {
            switch currentGuide {
            case .primary?: activeGuide = .secondary
            case .secondary?: activeGuide = .primary
            default: abort()
            }
        }
        
        if duration > 0 {
            UIView.animate(
                withDuration: duration,
                animations: _animations,
                completion: { _ in _completion() }
            )
        }
        else {
            _animations()
            _completion()
        }
    }
    
    private func adjustGuides(edge: ChartRange,
                              duration: TimeInterval) {
        let guidesPair = obtainGuides()
        let primaryAlpha = CGFloat(edge.distance > 0 ? 1.0 : 0)
        
        func _block() {
            layoutGuides(
                guides: guidesPair.primary,
                usingEdge: edge,
                startY: 0,
                height: bounds.height,
                alpha: primaryAlpha
            )
            
            for node in guidesPair.secondary {
                node.alpha = 0
            }
        }
        
        if (edge.distance == 0) == (lastEdge?.distance == 0) {
            _block()
        }
        else {
            let currentGuide = activeGuide
            activeGuide = nil
            
            UIView.animate(
                withDuration: duration,
                animations: _block,
                completion: { [unowned self] _ in
                    self.activeGuide = currentGuide
                }
            )
        }
    }
    
    private func obtainGuides() -> GuidesPair {
        switch activeGuide {
        case .none: return GuidesPair(primary: [], secondary: [])
        case .some(.primary): return GuidesPair(primary: primaryGuides, secondary: secondaryGuides)
        case .some(.secondary): return GuidesPair(primary: secondaryGuides, secondary: primaryGuides)
        }
    }
    
    private func layoutGuides(guides: [ChartGuideStepNode],
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
            let color = DesignBook.shared.color(step == 0 ? .chartPointerFocusedLineStroke : .chartGuidesLineStroke)
            
            let guide = guides[step]
            guide.frame = CGRect(x: 0, y: currentY, width: bounds.width, height: 20)
            guide.color = color
            
            if step == 0, usingEdge.distance == 0 {
                guide.value = formattingProvider.format(guide: 0)
                guide.alpha = 1.0
            }
            else {
                if usingEdge.distance > 0 {
                    guide.value = formattingProvider.format(guide: value)
                }
                
                guide.alpha = alpha
            }
        }
    }
}
