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
    case mainGraph
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
}

final class ChartSceneNode: ChartNode, IChartSceneNode {
    weak var delegate: IChartSceneDelegate?
    
    let graphNode: ChartMainGraphNode
    let timelineNode: ChartTimelineNode
    let navigatorNode: ChartNavigatorNode
    
    private var config: ChartConfig
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        self.config = config
        
        graphNode = ChartMainGraphNode(chart: chart, config: config, width: 2, formattingProvider: formattingProvider)
        timelineNode = ChartTimelineNode(chart: chart, config: config, formattingProvider: formattingProvider)
        navigatorNode = ChartNavigatorNode(chart: chart, config: config)

        super.init(frame: .zero)
        
        addSubview(graphNode)
        addSubview(timelineNode)
        addSubview(navigatorNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var frame: CGRect {
        didSet { layoutChildren() }
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        
        graphNode.update(config: config, duration: duration)
        timelineNode.update(config: config, duration: 0)
        navigatorNode.update(config: config, duration: duration)
    }
    
    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.primaryBackground)
        graphNode.updateDesign()
        timelineNode.updateDesign()
        navigatorNode.updateDesign()
    }
    
    private func layoutChildren() {
        let layout = Layout(bounds: bounds, config: config)
        graphNode.frame = layout.graphNodeFrame
        timelineNode.frame = layout.timelineFrame
        navigatorNode.frame = layout.navigatorFrame
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
    
    private let gaps = Layout.totalGaps
    private let timelineHeight = CGFloat(25)
    private let navigatorHeight = CGFloat(40)
    
    var graphNodeFrame: CGRect {
        let leftX = gaps.left
        let topY = gaps.bottom
        let width = bounds.width - gaps.right - leftX
        let height = timelineFrame.minY - topY
        return CGRect(x: leftX, y: topY, width: width, height: height)
    }
    
    var timelineFrame: CGRect {
        let topY = navigatorFrame.minY - timelineHeight
        let leftX = gaps.left
        let width = bounds.width - gaps.right - leftX
        return CGRect(x: leftX, y: topY, width: width, height: timelineHeight)
    }
    
    var navigatorFrame: CGRect {
        let leftX = gaps.left
        let topY = bounds.height - navigatorHeight
        let width = bounds.width - gaps.right - leftX
        return CGRect(x: leftX, y: topY, width: width, height: navigatorHeight)
    }
}
