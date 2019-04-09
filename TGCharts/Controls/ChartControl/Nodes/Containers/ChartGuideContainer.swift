//
//  ChartGuideContainer.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGuideContainer: IChartNode {
    func update(leftEdge: ChartRange?, rightEdge: ChartRange?, duration: TimeInterval)
}

final class ChartGuideContainer: ChartNode, IChartGuideContainer {
    let leftGuidesNode: ChartGuideControl
    let rightGuidesNode: ChartGuideControl
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        leftGuidesNode = ChartGuideControl(
            chart: chart,
            config: config,
            alignment: .left,
            pinned: true,
            formattingProvider: formattingProvider
        )
        
        rightGuidesNode = ChartGuideControl(
            chart: chart,
            config: config,
            alignment: .right,
            pinned: false,
            formattingProvider: formattingProvider
        )
        
        super.init(frame: .zero)
        
        leftGuidesNode.clipsToBounds = true
        addSubview(leftGuidesNode)
        
        rightGuidesNode.clipsToBounds = true
        addSubview(rightGuidesNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(leftEdge: ChartRange?, rightEdge: ChartRange?, duration: TimeInterval) {
        let emptyEdge = ChartRange(start: 0, end: 0)
        leftGuidesNode.update(edge: leftEdge ?? emptyEdge, duration: duration)
        rightGuidesNode.update(edge: rightEdge ?? emptyEdge, duration: duration)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        leftGuidesNode.frame = bounds
        rightGuidesNode.frame = bounds
    }
}
