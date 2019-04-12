//
//  ChartTimelineControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 16/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartTimelineControl: class {
}

final class ChartTimelineControl: ChartNode, IChartTimelineControl {
    private let chart: Chart
    private let formattingProvider: IFormattingProvider
    
    private var dateNodes = [ChartLabelNode]()
    
    private var config: ChartConfig
    private var overlap = UIEdgeInsets.zero
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = config
        self.formattingProvider = formattingProvider
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        
        dateNodes = chart.axis.reversed().map { item in
            let node = ChartLabelNode()
            node.text = formattingProvider.format(date: item.date, style: .shortDate)
            node.textColor = DesignBook.shared.color(.chartIndexForeground)
            node.font = UIFont.systemFont(ofSize: 8)
            node.textAlignment = .right
            addSubview(node)
            
            return node
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        update()
    }
    
    override func updateDesign() {
        super.updateDesign()
        colorizeDateNodes(dateNodes)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeDateNodes(dateNodes)
        update()
    }
    
    private func resizeDateNodes(_ nodes: [ChartLabelNode]) {
        let dateWidth = bounds.size.width / 7
        let height = bounds.size.height
        
        dateNodes.forEach { node in
            node.transform = .identity
            node.frame = CGRect(x: 0, y: 0, width: dateWidth, height: height)
        }
    }
    
    private func colorizeDateNodes(_ nodes: [ChartLabelNode]) {
        let color = DesignBook.shared.color(.chartIndexForeground)
        
        dateNodes.forEach { node in
            node.textColor = color
        }
    }
    
    private func update() {
        guard bounds.width > 0 else { return }
        guard config.range.distance > 0 else { return }

        let meta = chart.obtainMeta(
            config: config,
            bounds: bounds
        )
        
        let dateWidth = bounds.width / 7
        let totalWidth = bounds.width / config.range.distance
        let rightEdge = bounds.width + (1.0 - config.range.end) * totalWidth

        dateNodes.enumerated().reversed().forEach { index, node in
            let leftX = rightEdge - CGFloat(index) * meta.stepX - dateWidth
            node.transform = CGAffineTransform(translationX: leftX, y: 0)
        }

        adjustLayout(dateWidth: dateWidth, rightEdge: rightEdge, meta: meta)
    }
    
    private func calculateStep(dateWidth: CGFloat, rightEdge: CGFloat, meta: ChartSliceMeta) -> Int {
        let skippingNumber = Int(ceil(dateWidth / meta.stepX))
        return calculateCoveringDuoPower(value: skippingNumber)
    }
    
    private func adjustLayout(dateWidth: CGFloat, rightEdge: CGFloat, meta: ChartSliceMeta) {
        let skippingStep = calculateStep(dateWidth: dateWidth, rightEdge: rightEdge, meta: meta)
        let skippingSemiStep = max(1, skippingStep / 2)
        var lastAnchor = CGFloat(0)
        
        for (index, node) in dateNodes.enumerated() {
            if (index % skippingStep) == 0 {
                node.alpha = 1.0
                lastAnchor = node.frame.minX
            }
            else if (index % skippingSemiStep) == 0 {
                let distance = node.frame.maxX - lastAnchor
                let limit = node.frame.size.width * 0.25
                let value = 1.0 - min(1.0, distance / limit)
                node.alpha = value
            }
            else {
                node.alpha = 0
            }
        }
    }
}

private func calculateCoveringDuoPower(value: Int) -> Int {
    for i in (0 ..< 32).indices.reversed() {
        let bit = ((value & (1 << i)) > 0)
        guard bit else { continue }
        
        if value.nonzeroBitCount > 1 {
            return (1 << (i + 1))
        }
        else {
            return (1 << i)
        }
    }
    
    return 1
}
