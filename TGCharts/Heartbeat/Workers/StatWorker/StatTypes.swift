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

struct Chart {
    let length: Int
    let lines: [ChartLine]
    let axis: [ChartAxisItem]
    
    init() {
        length = 0
        axis = []
        lines = []
    }
    
    init(size: Int,
         axis: [ChartAxisItem],
         lines: [ChartLine]) {
        self.length = size
        self.axis = axis
        self.lines = lines
    }
    
    func visibleLines(config: ChartConfig) -> [ChartLine] {
        return zip(lines, config.lines).compactMap { line, lineConfig in
            guard lineConfig.visible else { return nil }
            return line
        }
    }
}

struct ChartAxisItem {
    let date: Date
    let values: [String: Int]
}

struct ChartLine {
    let key: String
    let name: String
    let color: UIColor
    let values: [Int]
}

struct ChartSlice {
    let lines: [ChartLine]
    let edge: ChartRange
}
