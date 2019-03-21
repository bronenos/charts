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
    private var sideOverlap = CGFloat(0)
    
    init(tag: String?, formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        super.init(tag: tag ?? "[timeline]")
    }
    
    override var frame: CGRect {
        didSet { update() }
    }
    
    func setChart(_ chart: Chart, config: ChartConfig, sideOverlap: CGFloat) {
        self.chart = chart
        self.config = config
        self.sideOverlap = sideOverlap
        update()
    }
    
    private func update() {
        removeAllChildren()
        
        guard let meta = obtainMeta(chart: chart, config: config, sideOverlap: sideOverlap) else { return }
        guard let firstRenderedIndex = meta.renderedIndices.first else { return }
        
        let dateWidth = size.width / 7
        let additionalNumberOfIndices = 0 // min(firstRenderedIndex, Int(ceil(dateWidth / meta.stepX)))
        let firstEnumeratedIndex = firstRenderedIndex - additionalNumberOfIndices
        
        var leftAnchor = CGFloat.infinity
        var skippingStep: Int?
        
        let axialSlice = chart.axis[firstEnumeratedIndex...].enumerated().reversed()
        let lastAxialIndex = axialSlice.count - 1
        guard lastAxialIndex >= 0 else { return }

        axialSlice.forEach { index, item in
            let rect = CGRect(
                x: -meta.margins.left + meta.stepX * CGFloat(index - additionalNumberOfIndices) - dateWidth,
                y: 0,
                width: dateWidth,
                height: size.height
            )
            
            let content = ChartLabelNodeContent(
                text: formattingProvider.format(date: item.date, style: .shortDate),
                color: DesignBook.shared.color(.chartIndexForeground),
                font: UIFont.systemFont(ofSize: 8),
                alignment: .right,
                limitedToBounds: false
            )
            
            let dateNode = ChartLabelNode(tag: "date")
            dateNode.frame = rect
            dateNode.content = content
            addChild(node: dateNode)
            
            if index == 0, rect.minX < 0 {
                dateNode.alpha = 0
            }
            else if rect.maxX <= leftAnchor {
                adjustBySkippingStep(
                    dateNode: dateNode,
                    leftAnchor: &leftAnchor,
                    index: index,
                    lastAxialIndex: lastAxialIndex,
                    skippingStep: &skippingStep
                )
            }
            else {
                dateNode.alpha = 0
            }
        }
    }
    
    private func adjustBySkippingStep(dateNode: IChartNode,
                                      leftAnchor: inout CGFloat,
                                      index: Int,
                                      lastAxialIndex: Int,
                                      skippingStep: inout Int?) {
        if index == lastAxialIndex {
            dateNode.alpha = 1.0
            leftAnchor = dateNode.frame.minX
        }
        else if let step = skippingStep {
            if ((lastAxialIndex - index) % step) == 0 {
                dateNode.alpha = 1.0
                leftAnchor = dateNode.frame.minX
            }
            else {
                dateNode.alpha = 0
            }
        }
        else {
            let step = lastAxialIndex - index
            if step.nonzeroBitCount == 1 {
                skippingStep = step
                dateNode.alpha = 1.0
                leftAnchor = dateNode.frame.minX
            }
            else {
                dateNode.alpha = 0
            }
        }
    }
}
