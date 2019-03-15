//
//  ChartScene.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartSceneNode: IChartNode {
    var graphNode: IChartGraphNode { get }
    var navigatorNode: IChartNavigatorNode { get }
    func setChart(_ chart: Chart, config: ChartConfig)
}

protocol IChartSceneDelegate: class {
}

final class ChartSceneNode: ChartNode, IChartSceneNode {
    let graphNode: IChartGraphNode = ChartGraphNode(tag: "graph")
    let navigatorNode: IChartNavigatorNode = ChartNavigatorNode(tag: "navigator")
    
    override init(tag: String?) {
        super.init(tag: tag ?? "[scene]")
        
        addChild(node: graphNode)
        addChild(node: navigatorNode)
    }
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        
        let frames = bounds.divided(atDistance: 40, from: .minYEdge)
        graphNode.setFrame(frames.remainder)
        navigatorNode.setFrame(frames.slice)
    }
    
    override func node(at point: CGPoint) -> IChartNode? {
        let flippedPoint = CGPoint(x: point.x, y: size.height - point.y)
        return super.node(at: flippedPoint)
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        graphNode.setChart(chart, config: config)
        navigatorNode.setChart(chart, config: config)
    }
}
