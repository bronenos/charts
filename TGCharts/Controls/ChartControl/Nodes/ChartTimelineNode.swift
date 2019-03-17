//
//  ChartTimelineNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 16/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartTimelineNode: IChartSlicableNode {
}

final class ChartTimelineNode: ChartNode, IChartTimelineNode {
    private let formattingProvider: IFormattingProvider
    
    private var dateNodes = [IChartLabelNode]()
    
    private var chart = Chart()
    private var config = ChartConfig()
    
    init(tag: String?, formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        super.init(tag: tag ?? "[timeline]")
    }
    
    override func setFrame(_ frame: CGRect) {
        super.setFrame(frame)
        update()
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        self.chart = chart
        self.config = config
        update()
    }
    
    private func update() {
        removeAllChildren()
        
        guard let meta = obtainMeta(chart: chart, config: config) else { return }
        
        chart.axis[meta.renderedIndices].enumerated().forEach { index, item in
            let rect = CGRect(
                x: -meta.margins.left + meta.stepX * CGFloat(index),
                y: 0,
                width: meta.stepX,
                height: size.height
            )
            
            let content = ChartLabelNodeContent(
                text: formattingProvider.format(date: item.date, style: .shortDate),
                color: DesignBook.shared.resolve(colorAlias: .chartIndexForeground),
                font: UIFont.systemFont(ofSize: 8),
                alignment: .left,
                limitedToBounds: false
            )
            
            let dateNode = ChartLabelNode(tag: "date")
            dateNode.setFrame(rect)
            dateNode.setContent(content)
            addChild(node: dateNode)
        }
    }
}
