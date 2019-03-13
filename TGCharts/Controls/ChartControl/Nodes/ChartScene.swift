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
}

final class ChartSceneNode: ChartNode, IChartSceneNode {
    let graphNode: IChartGraphNode = ChartGraphNode()
    let navigatorNode: IChartNavigatorNode = ChartNavigatorNode()
    
    override init() {
        super.init()
        
        addChild(node: graphNode)
        addChild(node: navigatorNode)
    }
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        
        let frames = bounds.divided(atDistance: 40, from: .minYEdge)
        graphNode.setFrame(frames.remainder)
        navigatorNode.setFrame(frames.slice)
    }
    
    func setChart(_ chart: StatChart, config: ChartConfig, range: ChartRange) {
        graphNode.setChart(chart, config: config, range: range)
        navigatorNode.setChart(chart, config: config, range: range)
    }
}
