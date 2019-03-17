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
    let renderedIndices: ClosedRange<Int>
    let visibleIndices: ClosedRange<Int>
    let totalWidth: CGFloat
    let margins: ChartMargins
    let stepX: CGFloat
}

protocol IChartSlicableNode: IChartNode {
    func setChart(_ chart: Chart, config: ChartConfig)
    func obtainMeta(chart: Chart, config: ChartConfig) -> ChartSliceMeta?
}

extension IChartSlicableNode {
    func obtainMeta(chart: Chart, config: ChartConfig) -> ChartSliceMeta? {
        guard chart.length > 0 else { return nil }
        guard config.range.distance > 0 else { return nil }
        
        let lastIndex = CGFloat(chart.length - 1)
        
        let leftRenderedIndex = Int(floor(lastIndex * config.range.start))
        let rightRenderedIndex = Int(ceil(lastIndex * config.range.end))
        let renderedIndices = (leftRenderedIndex ... rightRenderedIndex)
        
        let leftVisibleIndex = Int(ceil(lastIndex * config.range.start))
        let rightVisibleIndex = Int(floor(lastIndex * config.range.end))
        let visibleIndices = (leftVisibleIndex ... rightVisibleIndex)
        
        let totalWidth = size.width / config.range.distance
        let stepX = totalWidth / lastIndex
        
        let leftRenderedItemPosition = CGFloat(leftRenderedIndex) * stepX
        let frameLeftPosition = CGFloat(totalWidth * config.range.start)
        
        let rightRenderedItemPosition = CGFloat(rightRenderedIndex) * stepX
        let frameRightPosition = CGFloat(totalWidth * config.range.end)
        
        return ChartSliceMeta(
            renderedIndices: renderedIndices,
            visibleIndices: visibleIndices,
            totalWidth: totalWidth,
            margins: ChartMargins(
                left: frameLeftPosition - leftRenderedItemPosition,
                right: rightRenderedItemPosition - frameRightPosition
            ),
            stepX: stepX
        )
    }
}
