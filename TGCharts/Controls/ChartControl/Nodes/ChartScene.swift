//
//  ChartScene.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum ChartControlTag: Int {
    case unknown
    case graph
    case navigator
    case slider
    case leftArrow
    case rightArrow
}

protocol IChartSceneNode: IChartNode {
    var delegate: IChartSceneDelegate? { get set }
    func update(config: ChartConfig, duration: TimeInterval)
}

protocol IChartSceneDelegate: class {
    func sceneDidToggleLine(index: Int)
}

final class ChartSceneNode: ChartNode, IChartSceneNode {
    weak var delegate: IChartSceneDelegate?
    
    let headerNode: ChartHeader
    let graphContainer: ChartGraphContainer
    let timelineNode: ChartTimelineControl
    let navigatorNode: ChartNavigatorControl
    let optionsNode: ChartOptionsControl
    
    private let chart: Chart
    private var config: ChartConfig
    
    init(chart: Chart, config: ChartConfig, localeProvider: ILocaleProvider, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = config
        
        headerNode = ChartHeader(zoomOutTitle: localeProvider.localize(key: "Chart.Control.ZoomOut"), formattingProvider: formattingProvider)
        graphContainer = ChartGraphContainer(chart: chart, config: config, formattingProvider: formattingProvider, enableControls: true)
        timelineNode = ChartTimelineControl(chart: chart, config: config, formattingProvider: formattingProvider)
        navigatorNode = ChartNavigatorControl(chart: chart, config: config, formattingProvider: formattingProvider)
        optionsNode = ChartOptionsControl()

        super.init(frame: .zero)
        
        addSubview(headerNode)
        addSubview(graphContainer)
        addSubview(timelineNode)
        addSubview(navigatorNode)
        addSubview(optionsNode)
        
        let mainGraph = obtainGraph(chart: chart, config: config, formattingProvider: formattingProvider, width: 2)
        graphContainer.inject(graph: mainGraph)
        
        let miniGraph = obtainGraph(chart: chart, config: config, formattingProvider: formattingProvider, width: 1)
        navigatorNode.inject(graph: miniGraph)
        
        populateOptions(chart: chart, config: config)
        updateDesign()
        
        optionsNode.tokenTapHandler = { [weak self] index in
            self?.delegate?.sceneDidToggleLine(index: index)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        
        graphContainer.update(config: config, duration: duration)
        timelineNode.update(config: config, duration: 0)
        navigatorNode.update(config: config, duration: duration)
        populateOptions(chart: chart, config: config)
    }
    
    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.primaryBackground)
        headerNode.updateDesign()
        graphContainer.updateDesign()
        timelineNode.updateDesign()
        navigatorNode.updateDesign()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: bounds.size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        headerNode.frame = layout.headerNodeFrame
        graphContainer.frame = layout.graphContainerFrame
        timelineNode.frame = layout.timelineFrame
        navigatorNode.frame = layout.navigatorFrame
        optionsNode.frame = layout.optionsNodeFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            config: config,
            headerNode: headerNode,
            graphContainer: graphContainer,
            optionsNode: optionsNode
        )
    }
    
    private func obtainGraph(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, width: CGFloat) -> ChartGraphNode {
        switch chart.type {
        case .duo: return ChartDuoGraphNode(chart: chart, config: config, formattingProvider: formattingProvider, width: width)
        case .bar: return ChartBarGraphNode(chart: chart, config: config, formattingProvider: formattingProvider)
        case .area: return ChartAreaGraphNode(chart: chart, config: config, formattingProvider: formattingProvider)
        default: return ChartLineGraphNode(chart: chart, config: config, formattingProvider: formattingProvider, width: width)
        }
    }
    
    private func populateOptions(chart: Chart, config: ChartConfig) {
        optionsNode.populate(
            zip(chart.lines, config.lines).map { line, lineConfig in
                ChartOptionsItem(
                    key: line.key,
                    color: line.color,
                    title: line.name,
                    enabled: lineConfig.visible
                )
            }
        )
    }
}

fileprivate struct Layout {
    static func gaps(bottom: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: bottom, right: 15)
    }
    
    static let totalGaps = Layout.gaps(bottom: 5)
    static let sideGaps = Layout.gaps(bottom: 0)

    let bounds: CGRect
    let config: ChartConfig
    let headerNode: ChartHeader
    let graphContainer: ChartGraphContainer
    let optionsNode: ChartOptionsControl
    
    private let gaps = Layout.totalGaps
    private let graphHeight = CGFloat(300)
    private let timelineHeight = CGFloat(25)
    private let navigatorHeight = CGFloat(40)
    
    var headerNodeFrame: CGRect {
        let size = headerNode.sizeThatFits(.zero)
        return CGRect(x: 0, y: 0, width: bounds.width, height: size.height)
    }
    
    var graphContainerFrame: CGRect {
        let leftX = gaps.left
        let topY = headerNodeFrame.maxY + gaps.bottom
        let width = bounds.width - gaps.right - leftX
        let height = graphContainer.sizeThatFits(.zero).height
        return CGRect(x: leftX, y: topY, width: width, height: height)
    }
    
    var timelineFrame: CGRect {
        let topY = graphContainerFrame.maxY
        let leftX = gaps.left
        let width = bounds.width - gaps.right - leftX
        return CGRect(x: leftX, y: topY, width: width, height: timelineHeight)
    }
    
    var navigatorFrame: CGRect {
        let topY = timelineFrame.maxY
        let leftX = gaps.left
        let width = bounds.width - gaps.right - leftX
        return CGRect(x: leftX, y: topY, width: width, height: navigatorHeight)
    }
    
    var optionsNodeFrame: CGRect {
        let size = optionsNode.sizeThatFits(bounds.insetBy(dx: gaps.left, dy: 0).size)
        let leftX = gaps.left
        let topY = navigatorFrame.maxY
        let width = bounds.width - gaps.right - leftX
        return CGRect(x: leftX, y: topY, width: width, height: size.height)
    }
    
    var totalSize: CGSize {
        return CGSize(width: bounds.width, height: optionsNodeFrame.maxY)
    }
}
