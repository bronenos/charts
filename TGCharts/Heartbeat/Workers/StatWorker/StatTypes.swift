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
    case ready([StatChart])
}

struct StatChart {
    let size: Int
    let axis: StatChartAxis
    let lines: [StatChartLine]
    
    init() {
        size = 0
        axis = StatChartAxis(dates: [])
        lines = []
    }
    
    init(size: Int,
         axis: StatChartAxis,
         lines: [StatChartLine]) {
        self.size = size
        self.axis = axis
        self.lines = lines
    }
    
    func visibleLines(config: ChartConfig) -> [StatChartLine] {
        return zip(lines, config.lines).compactMap { line, lineConfig in
            guard lineConfig.visible else { return nil }
            return line
        }
    }
}

struct StatChartPresentingState {
    var visibleLines: [String]
}

struct StatChartAxis {
    let dates: [Date]
}

struct StatChartLine {
    let key: String
    let name: String
    let color: UIColor
    let values: [Int]
}
