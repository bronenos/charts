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
    let leftOverlappingIndex: CGFloat?
    let rightOverlappingIndex: CGFloat?
    let totalWidth: CGFloat
    let margins: ChartMargins
    let stepX: CGFloat
}

protocol IChartSlicableNode: IChartNode {
    func setChart(_ chart: Chart, config: ChartConfig, sideOverlap: CGFloat)
    func obtainMeta(chart: Chart, config: ChartConfig, sideOverlap: CGFloat) -> ChartSliceMeta?
}

extension IChartSlicableNode {
    func obtainMeta(chart: Chart, config: ChartConfig, sideOverlap: CGFloat) -> ChartSliceMeta? {
        guard chart.length > 0 else { return nil }
        guard config.range.distance > 0 else { return nil }
        
        let lastIndex = CGFloat(chart.length - 1)
        let totalWidth = size.width / config.range.distance
        let stepX = totalWidth / lastIndex
        
        let sideIndices = ceil(sideOverlap / stepX)
        
        let leftFramePosition = CGFloat(totalWidth * config.range.start)
        let leftRenderedIndex = Int(floor(max(0, lastIndex * config.range.start - sideIndices)))
        let leftRenderedPosition = CGFloat(leftRenderedIndex) * stepX
        let leftVisiblePosition = max(0, leftFramePosition - sideOverlap)
        let leftVisibleIndex = Int(ceil(leftVisiblePosition / stepX))

        let rightFramePosition = CGFloat(totalWidth * config.range.end)
        let rightRenderedIndex = Int(ceil(min(lastIndex, lastIndex * config.range.end + sideIndices)))
        let rightRenderedPosition = CGFloat(rightRenderedIndex) * stepX
        let rightVisiblePosition = min(totalWidth, rightFramePosition + sideOverlap)
        let rightVisibleIndex = Int(floor(rightVisiblePosition / stepX))

        let renderedIndices = (leftRenderedIndex ... rightRenderedIndex)
        let visibleIndices = (leftVisibleIndex ... rightVisibleIndex)
        
        if config.range.distance < 0.5 {
            print("")
        }
        
        let leftOverlappingIndex: CGFloat?
        if leftVisibleIndex > leftRenderedIndex {
            let leftVirtualPosition = leftRenderedPosition + stepX
            let coef = (leftVisiblePosition - leftRenderedPosition) / (leftVirtualPosition - leftRenderedPosition)
            leftOverlappingIndex = CGFloat(leftRenderedIndex) + coef
        }
        else {
            leftOverlappingIndex = nil
        }
        
        let rightOverlappingIndex: CGFloat?
        if rightVisibleIndex < rightRenderedIndex {
            let rightVirtualPosition = rightRenderedPosition - stepX
            let coef = (rightVisiblePosition - rightVirtualPosition) / (rightRenderedPosition - rightVirtualPosition)
            rightOverlappingIndex = CGFloat(rightRenderedIndex - 1) + coef
        }
        else {
            rightOverlappingIndex = nil
        }

        return ChartSliceMeta(
            renderedIndices: renderedIndices,
            visibleIndices: visibleIndices,
            leftOverlappingIndex: leftOverlappingIndex,
            rightOverlappingIndex: rightOverlappingIndex,
            totalWidth: totalWidth,
            margins: ChartMargins(
                left: leftFramePosition - leftRenderedPosition,
                right: rightRenderedPosition - rightFramePosition
            ),
            stepX: stepX
        )
    }
}
