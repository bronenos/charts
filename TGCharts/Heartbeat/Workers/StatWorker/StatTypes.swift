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
    let length: Int
    let lines: [ChartLine]
    let axis: [ChartAxisItem]
    
    init() {
        length = 0
        lines = []
        axis = []
    }
    
    init(length: Int,
         lines: [ChartLine],
         axis: [ChartAxisItem]) {
        self.length = length
        self.lines = lines
        self.axis = axis
    }
    
    func visibleLines(config: ChartConfig) -> [ChartLine] {
        return zip(lines, config.lines).compactMap { line, lineConfig in
            guard lineConfig.visible else { return nil }
            return line
        }
    }
    
    static func ==(lhs: Chart, rhs: Chart) -> Bool {
        guard lhs.length == rhs.length else { return false }
        guard lhs.lines == rhs.lines else { return false }
        guard lhs.axis == rhs.axis else { return false }
        return true
    }
}

struct ChartAxisItem: Equatable {
    let date: Date
    let values: [String: Int]
    
    static func ==(lhs: ChartAxisItem, rhs: ChartAxisItem) -> Bool {
        guard lhs.date == rhs.date else { return false }
        guard lhs.values == rhs.values else { return false }
        return true
    }
}

struct ChartLine: Equatable {
    let key: String
    let name: String
    let color: UIColor
    let values: [Int]
    
    static func ==(lhs: ChartLine, rhs: ChartLine) -> Bool {
        guard lhs.key == rhs.key else { return false }
        guard lhs.name == rhs.name else { return false }
        guard lhs.color == rhs.color else { return false }
        guard lhs.values == rhs.values else { return false }
        return true
    }
}

struct ChartSlice {
    let lines: [ChartLine]
    let edge: ChartRange
}
