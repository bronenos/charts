//
//  StatTypes.swift
//  TGCharts
//
//  Created by Stan Potemkin on 10/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum StatLoadingState {
    case unknown
    case waiting
    case ready([Chart])
}

struct Chart: Equatable {
    let type: ChartType
    let length: Int
    let lines: [ChartLine]
    let axis: [ChartAxisItem]
    let children: [String: URL]
    
    init(type: ChartType,
         length: Int,
         lines: [ChartLine],
         axis: [ChartAxisItem],
         children: [String: URL]) {
        self.type = type
        self.length = length
        self.lines = lines
        self.axis = axis
        self.children = children
    }
    
    func obtainMeta(config: ChartConfig, bounds: CGRect) -> ChartSliceMeta {
        let emptySlice = ChartSliceMeta(
            bounds: bounds,
            config: config,
            range: config.range,
            totalWidth: 0,
            stepX: 0,
            visibleIndices: (0 ..< 0)
        )
        
        guard bounds.size.width > 0 else { return emptySlice }
        guard length > 0 else { return emptySlice }
        guard config.range.distance > 0 else { return emptySlice }
        
        let totalWidth = bounds.size.width / config.range.distance
        let stepX = totalWidth / CGFloat(length - 1)
        let startIndex = Int(floor((totalWidth * config.range.start) / stepX))
        let endIndex = Int(ceil((totalWidth * config.range.end) / stepX))
        
        return ChartSliceMeta(
            bounds: bounds,
            config: config,
            range: config.range,
            totalWidth: totalWidth,
            stepX: stepX,
            visibleIndices: (max(0, startIndex) ..< min(length, endIndex))
        )
    }
    
    func visibleLines(config: ChartConfig) -> [ChartLine] {
        return zip(lines, config.lines).compactMap { line, lineConfig in
            if lineConfig.visible { return line }
            return nil
        }
    }
    
    static func ==(lhs: Chart, rhs: Chart) -> Bool {
        guard lhs.type == rhs.type else { return false }
        guard lhs.length == rhs.length else { return false }
        guard lhs.lines == rhs.lines else { return false }
        guard lhs.axis == rhs.axis else { return false }
        return true
    }
}

enum ChartType: String {
    case line
    case duo
    case bar
    case area
    case pie
}

struct ChartAxisItem: Equatable, Comparable {
    let date: Date
    let values: [String: Int]
    
    static func ==(lhs: ChartAxisItem, rhs: ChartAxisItem) -> Bool {
        guard lhs.date == rhs.date else { return false }
        guard lhs.values == rhs.values else { return false }
        return true
    }
    
    static func <(lhs: ChartAxisItem, rhs: ChartAxisItem) -> Bool {
        return lhs.date < rhs.date
    }
}

struct ChartLine: Equatable {
    let key: String
    let name: String
    let type: String
    let color: UIColor
    let values: [Int]
    
    static func ==(lhs: ChartLine, rhs: ChartLine) -> Bool {
        guard lhs.key == rhs.key else { return false }
        guard lhs.name == rhs.name else { return false }
        guard lhs.type == rhs.type else { return false }
        guard lhs.color == rhs.color else { return false }
        guard lhs.values == rhs.values else { return false }
        return true
    }
}

struct ChartSlice {
    let lines: [ChartLine]
    let edge: ChartRange
}
