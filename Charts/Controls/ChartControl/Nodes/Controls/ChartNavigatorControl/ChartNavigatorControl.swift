//
//  ChartNavigatorControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class ChartNavigatorOptions {
    let caretStandardDistance: CGFloat
    private(set) var caretStandardWidth: CGFloat
    
    private let caretDefaultWidth = CGFloat(50)

    init(caretStandardDistance: CGFloat) {
        self.caretStandardDistance = caretStandardDistance
        self.caretStandardWidth = caretDefaultWidth
    }
    
    func update(caretStandardWidth: CGFloat) {
        self.caretStandardWidth = max(caretDefaultWidth, caretStandardWidth)
    }
}

protocol IChartNavigatorControl: IChartNode {
    func inject(graph: ChartGraphNode)
    func update(config: ChartConfig, duration: TimeInterval, wantsActualEye: Bool)
}

final class ChartNavigatorControl: ChartNode, IChartNavigatorControl {
    let spaceNode = ChartNode()
    let graphContainer: ChartGraphContainer
    let leftDim = ChartNode()
    let rightDim = ChartNode()
    let sliderNode = ChartSliderNode()
    
    private let options: ChartNavigatorOptions
    private var calculator: NavigatingCalculator
    private var config: ChartConfig
    private var currentGraph: ChartGraphNode?

    init(chart: Chart, config: ChartConfig, options: ChartNavigatorOptions, formattingProvider: IFormattingProvider) {
        self.options = options
        self.calculator = NavigatingCalculator(options: options, bounds: .zero, range: config.range)
        self.config = config

        graphContainer = ChartGraphContainer(
            chart: chart,
            config: config,
            headerNode: nil,
            formattingProvider: formattingProvider,
            mainGraphHeight: 25,
            enableControls: false
        )
        
        super.init(frame: .zero)
        
        tag = ChartControlTag.navigator.rawValue
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        addSubview(spaceNode)
        addSubview(graphContainer)
        addSubview(leftDim)
        addSubview(rightDim)
        addSubview(sliderNode)
        
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func inject(graph: ChartGraphNode) {
        currentGraph = graph
        graphContainer.inject(graph: graph)
    }
    
    func update(config: ChartConfig, duration: TimeInterval, wantsActualEye: Bool) {
        let oldConfig = self.config
        self.config = config
        
        options.update(
            caretStandardWidth: DesignBook.shared.caretStandardWidth(navigationWidth: bounds.width)
        )
        
        setNeedsLayout()
        layoutIfNeeded()
        
        if let graph = currentGraph {
            let fittingConfig = config.withRange(range: calculator.graphCurrentRange)
            let shouldForceUpdate = graph.shouldReset(newConfig: config, oldConfig: oldConfig)
            let caretOriginalWidth = graph.bounds.width * options.caretStandardDistance
            let graphFits = (abs(caretOriginalWidth - options.caretStandardWidth) < 0.1)
            
            if !wantsActualEye || shouldForceUpdate {
                graph.update(config: fittingConfig, shouldUpdateEye: false, duration: duration)
            }
            else if graphFits {
                graph.updateVisibility(config: fittingConfig, duration: duration)
            }
            else {
                graph.update(config: fittingConfig, shouldUpdateEye: true, duration: duration)
            }
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.navigatorBackground)
        spaceNode.backgroundColor = DesignBook.shared.color(.primaryBackground)
        leftDim.backgroundColor = DesignBook.shared.color(.navigatorCoverBackground)
        rightDim.backgroundColor = DesignBook.shared.color(.navigatorCoverBackground)
        sliderNode.updateDesign()
        graphContainer.updateDesign()
    }
    
    override func discardCache() {
        super.discardCache()
        graphContainer.discardCache()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        calculator = NavigatingCalculator(
            options: options,
            bounds: bounds,
            range: config.range
        )
        
        let layout = getLayout(size: bounds.size)
        graphContainer.frame = layout.graphContainerFrame
        spaceNode.frame = layout.spaceNodeFrame
        leftDim.frame = layout.leftDimFrame
        rightDim.frame = layout.rightDimFrame
        sliderNode.frame = layout.sliderNodeFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: bounds,
            verticalGap: sliderNode.verticalGap,
            sliderArrowWidth: sliderNode.horizontalGap,
            navigatingCalculator: calculator
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let verticalGap: CGFloat
    let sliderArrowWidth: CGFloat
    let navigatingCalculator: NavigatingCalculator

    var graphContainerFrame: CGRect {
        let leftX = navigatingCalculator.graphCurrentX
        let width = navigatingCalculator.graphCurrentWidth
        return CGRect(x: leftX, y: 0, width: width, height: bounds.height).insetBy(dx: 0, dy: verticalGap)
    }
    
    var spaceNodeFrame: CGRect {
        return sliderNodeFrame
    }
    
    var leftDimFrame: CGRect {
        let leftX = sliderNodeFrame.minX + sliderArrowWidth
        return bounds
            .divided(atDistance: leftX, from: .minXEdge).slice
            .insetBy(dx: 0, dy: verticalGap)
    }
    
    var rightDimFrame: CGRect {
        let rightX = sliderNodeFrame.maxX - sliderArrowWidth
        return bounds
            .divided(atDistance: rightX, from: .minXEdge).remainder
            .insetBy(dx: 0, dy: verticalGap)
    }
    
    var sliderNodeFrame: CGRect {
        let leftX = navigatingCalculator.caretCurrentX
        let width = navigatingCalculator.caretCurrentWidth
        return CGRect(x: leftX, y: 0, width: width, height: bounds.height)
    }
}
