//
//  ChartGuideControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartGuideOptions: Equatable {
    let range: ChartRange
    let numberOfSteps: Int
    let closeToBounds: Bool
    let textColor: UIColor?
    let reversedAnimations: Bool
}

protocol IChartGuideControl: IChartNode {
    func update(options: ChartGuideOptions?, duration: TimeInterval)
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
    
    private let chart: Chart
    private let alignment: NSTextAlignment
    private let formattingProvider: IFormattingProvider

    private var primaryGuides = [ChartGuideStepNode]()
    private var secondaryGuides = [ChartGuideStepNode]()
    
    private var options: ChartGuideOptions?
    private var lastOptions: ChartGuideOptions?
    private var activeGuide: VerticalActiveGuide? = .primary
    
    init(chart: Chart, config: ChartConfig, alignment: NSTextAlignment, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.alignment = alignment
        self.formattingProvider = formattingProvider
        
        super.init(frame: .zero)
        
        recreateGuides()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(options: ChartGuideOptions?, duration: TimeInterval) {
        let oldOptions = self.options
        self.options = options
        
        if options?.textColor != oldOptions?.textColor {
            recreateGuides()
        }
        else if options?.numberOfSteps != oldOptions?.numberOfSteps {
            recreateGuides()
        }

        update(options: options, duration: duration, force: false)
    }
    
    private func update(options: ChartGuideOptions?, duration: TimeInterval, force: Bool) {
        guard let activeGuide = activeGuide else { return }
        let guidesPair = obtainGuides()
        
        guard (options != lastOptions) || force else { return }
        defer { lastOptions = options }
        
        if let options = options {
            if let lastOptions = lastOptions, !isMinorChange(from: lastOptions, to: options) {
                exchangeGuides(
                    options: options,
                    lastOptions: lastOptions,
                    duration: duration
                )
            }
            else {
                adjustGuides(
                    options: options,
                    duration: duration
                )
            }
        }
        else {
            adjustGuides(
                options: ChartGuideOptions(
                    range: .empty,
                    numberOfSteps: 1,
                    closeToBounds: false,
                    textColor: nil,
                    reversedAnimations: false
                ),
                duration: duration
            )
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        primaryGuides.forEach { $0.underlineColor = DesignBook.shared.color(.chartGridStroke) }
        secondaryGuides.forEach { $0.underlineColor = DesignBook.shared.color(.chartGridStroke) }
        
        if let options = lastOptions {
            update(options: options, duration: 0, force: true)
        }
    }
    
    private func recreateGuides() {
        primaryGuides.forEach { $0.removeFromSuperview() }
        secondaryGuides.forEach { $0.removeFromSuperview() }

        if let options = options {
            clipsToBounds = !options.closeToBounds
            
            primaryGuides = (0 ..< options.numberOfSteps).map { _ in ChartGuideStepNode(alignment: alignment) }
            primaryGuides.forEach { node in
                node.autoresizingMask = [.flexibleWidth]
                node.alpha = 1.0
                addSubview(node)
            }
            
            secondaryGuides = (0 ..< options.numberOfSteps).map { _ in ChartGuideStepNode(alignment: alignment) }
            secondaryGuides.forEach { node in
                node.autoresizingMask = [.flexibleWidth]
                node.alpha = 0
                addSubview(node)
            }
        }
        else {
            clipsToBounds = true
        }
    }
    
    private func isMinorChange(from: ChartGuideOptions, to: ChartGuideOptions) -> Bool {
        if !(from.range.distance > 0 && to.range.distance > 0) {
            return true
        }
        
        let growth = abs(from.range.distance - to.range.distance)
        if (growth / max(from.range.distance, to.range.distance)) > 0.1 {
            return false
        }
        else {
            return true
        }
    }
    
    private func exchangeGuides(options: ChartGuideOptions,
                                lastOptions: ChartGuideOptions,
                                duration: TimeInterval) {
        let guidesPair = obtainGuides()
        
        let scalingCoef = lastOptions.range.distance / options.range.distance
        let startDiff = options.range.start - lastOptions.range.start
        
        let relativeFromPosition = (startDiff / lastOptions.range.distance) * bounds.height
        let adjustFromPosition = -relativeFromPosition * (1 + scalingCoef)
        
        let relativeHeight = (lastOptions.range.distance / options.range.distance)
        let sourceToHeight = bounds.height / relativeHeight
        let destinationToHeight = bounds.height
        
        layoutGuides(
            guides: guidesPair.primary,
            usingOptions: lastOptions,
            startY: 0,
            height: bounds.height,
            alpha: 1.0
        )
        
        layoutGuides(
            guides: guidesPair.secondary,
            usingOptions: options,
            startY: relativeFromPosition,
            height: sourceToHeight,
            alpha: 0
        )
        
        let currentGuide = activeGuide
        activeGuide = nil
        
        func _animations() {
            layoutGuides(
                guides: guidesPair.primary,
                usingOptions: lastOptions,
                startY: adjustFromPosition,
                height: destinationToHeight * scalingCoef,
                alpha: 0
            )
            
            layoutGuides(
                guides: guidesPair.secondary,
                usingOptions: options,
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
                delay: 0,
                options: [.curveEaseInOut],
                animations: _animations,
                completion: { _ in _completion() }
            )
        }
        else {
            _animations()
            _completion()
        }
    }
    
    private func adjustGuides(options: ChartGuideOptions,
                              duration: TimeInterval) {
        let guidesPair = obtainGuides()
        let primaryAlpha = CGFloat(options.range.distance > 0 ? 1.0 : 0)
        
        func _block(alpha: CGFloat?) {
            layoutGuides(
                guides: guidesPair.primary,
                usingOptions: options,
                startY: 0,
                height: bounds.height,
                alpha: alpha ?? primaryAlpha
            )
            
            for node in guidesPair.secondary {
                node.alpha = 0
            }
        }
        
        if (options.range.distance == 0) == (lastOptions?.range.distance == 0) {
            _block(alpha: nil)
        }
//        else if let last = lastOptions?.range, (last.distance > 0) != (options.range.distance > 0) {
//            _block(alpha: 0)
//
//            let currentGuide = activeGuide
//            activeGuide = nil
//
//            UIView.animate(
//                withDuration: duration,
//                delay: 0,
//                options: [],
//                animations: { _block(alpha: nil) },
//                completion: { [weak self] _ in
//                    self?.activeGuide = currentGuide
//                }
//            )
//        }
        else {
            let currentGuide = activeGuide
            activeGuide = nil
            
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [],
                animations: { _block(alpha: nil) },
                completion: { [weak self] _ in
                    self?.activeGuide = currentGuide
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
                              usingOptions: ChartGuideOptions,
                              startY: CGFloat,
                              height: CGFloat,
                              alpha: CGFloat) {
        guard let options = options else { return }
        
        let stepY: CGFloat = convertMap(options.closeToBounds) { closeToBounds in
            let numberOfSteps = options.numberOfSteps - (closeToBounds ? 1 : 0)
            return (height - 1) / CGFloat(numberOfSteps)
        }
        
        let stepValue: CGFloat = convertMap(options.closeToBounds) { closeToBounds in
            let numberOfSteps = options.numberOfSteps - (closeToBounds ? 1 : 0)
            return usingOptions.range.distance / CGFloat(numberOfSteps)
        }
        
        (0 ..< options.numberOfSteps).forEach { step in
            let height = CGFloat(20)
            let value = Int(usingOptions.range.start + CGFloat(step) * stepValue)
            let currentY = bounds.height - (startY + CGFloat(step) * stepY) - height
            
            let guide = guides[step]
            guide.frame = CGRect(x: 0, y: currentY, width: bounds.width, height: 20)
            
            guide.valueColor = options.textColor
            guide.underlineColor = DesignBook.shared.color(.chartGridStroke)
            
            if step == 0, usingOptions.range.distance == 0 {
                guide.value = formattingProvider.format(guide: 0)
                guide.alpha = 1.0
            }
            else {
                if usingOptions.range.distance > 0 {
                    guide.value = formattingProvider.format(guide: value)
                }
                
                guide.alpha = alpha
            }
        }
    }
}
