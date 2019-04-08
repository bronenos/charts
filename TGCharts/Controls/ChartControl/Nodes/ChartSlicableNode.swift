//
//  ChartSlicableNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 16/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartSliceMeta {
    let totalWidth: CGFloat
    let stepX: CGFloat
    let visibleIndices: Range<Int>
}

protocol IChartSlicableNode: IChartNode {
    func update(config: ChartConfig, duration: TimeInterval)
    func obtainMeta(chart: Chart, config: ChartConfig) -> ChartSliceMeta?
}

extension IChartSlicableNode where Self: UIView {
    func obtainMeta(chart: Chart, config: ChartConfig) -> ChartSliceMeta? {
        guard bounds.size.width > 0 else { return nil }
        guard chart.length > 0 else { return nil }
        guard config.range.distance > 0 else { return nil }
        
        let lastIndex = CGFloat(chart.length - 1)
        let totalWidth = bounds.size.width / config.range.distance
        let stepX = totalWidth / lastIndex
        let startIndex = Int(floor((totalWidth * config.range.start) / stepX))
        let endIndex = Int(ceil((totalWidth * config.range.end) / stepX))
        
        return ChartSliceMeta(
            totalWidth: totalWidth,
            stepX: stepX,
            visibleIndices: (max(0, startIndex) ..< min(chart.length, endIndex))
        )
    }
}
