//
//  ChartNavigatorControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartNavigatorOptions {
    let caretStandardWidth: CGFloat
    let caretStandardDistance: CGFloat
}

protocol IChartNavigatorControl: IChartNode {
    func inject(graph: ChartGraphNode)
    func update(config: ChartConfig, duration: TimeInterval, needsRecalculate: Bool)
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
            formattingProvider: formattingProvider,
            enableControls: false
        )
        
        super.init(frame: .zero)
        
        tag = ChartControlTag.navigator.rawValue
        clipsToBounds = true
        
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
    
    func update(config: ChartConfig, duration: TimeInterval, needsRecalculate: Bool) {
        self.config = config
        
        setNeedsLayout()
        layoutIfNeeded()
        
        currentGraph?.update(
            config: config.withRange(range: calculator.graphCurrentRange),
            duration: duration,
            needsRecalculate: needsRecalculate
        )
    }
    
    override func updateDesign() {
        super.updateDesign()
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
            navigatingCalculator: calculator
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let verticalGap: CGFloat
    let navigatingCalculator: NavigatingCalculator

    var graphContainerFrame: CGRect {
        let topY = verticalGap * 2
        let leftX = navigatingCalculator.graphCurrentX
        let width = navigatingCalculator.graphCurrentWidth
        let height = bounds.height - topY * 2
        return CGRect(x: leftX, y: topY, width: width, height: height)
    }
    
    var spaceNodeFrame: CGRect {
        return sliderNodeFrame
    }
    
    var leftDimFrame: CGRect {
        let leftX = sliderNodeFrame.minX
        return bounds.divided(atDistance: leftX, from: .minXEdge).slice
    }
    
    var rightDimFrame: CGRect {
        let rightX = sliderNodeFrame.maxX
        return bounds.divided(atDistance: rightX, from: .minXEdge).remainder
    }
    
    var sliderNodeFrame: CGRect {
        let leftX = navigatingCalculator.caretCurrentX
        let width = navigatingCalculator.caretCurrentWidth
        let value = CGRect(x: leftX, y: 0, width: width, height: bounds.height)
        return value
    }
}
