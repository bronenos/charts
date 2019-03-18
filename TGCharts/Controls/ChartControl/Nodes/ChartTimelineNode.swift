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
    
    override var frame: CGRect {
        didSet { update() }
    }
    
    func setChart(_ chart: Chart, config: ChartConfig) {
        self.chart = chart
        self.config = config
        update()
    }
    
    private func update() {
        removeAllChildren()
        
        guard let meta = obtainMeta(chart: chart, config: config) else { return }
        guard let firstRenderedIndex = meta.renderedIndices.first else { return }
        
        let dateWidth = size.width / 7
        let additionalNumberOfIndices = min(firstRenderedIndex, Int(ceil(dateWidth / meta.stepX)))
        let firstEnumeratedIndex = firstRenderedIndex - additionalNumberOfIndices
        
        var leftAnchor = CGFloat.infinity
        chart.axis[firstEnumeratedIndex...].enumerated().reversed().forEach { index, item in
            let rect = CGRect(
                x: CGFloat(-additionalNumberOfIndices) * meta.stepX - meta.margins.left + meta.stepX * CGFloat(index),
                y: 0,
                width: dateWidth,
                height: size.height
            )
            
            let content = ChartLabelNodeContent(
                text: formattingProvider.format(date: item.date, style: .shortDate),
                color: DesignBook.shared.resolve(colorAlias: .chartIndexForeground),
                font: UIFont.systemFont(ofSize: 8),
                alignment: .right,
                limitedToBounds: false
            )
            
            let dateNode = ChartLabelNode(tag: "date")
            dateNode.frame = rect
            dateNode.content = content
            addChild(node: dateNode)
            
            if rect.maxX <= leftAnchor {
                dateNode.alpha = 1.0
                leftAnchor = rect.minX
            }
            else {
                dateNode.alpha = 0
            }
        }
    }
}
