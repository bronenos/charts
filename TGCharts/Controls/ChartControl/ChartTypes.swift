//
//  ChartTypes.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartConfig {
    var lines: [ChartLineConfig]
    var range: ChartRange
    
    init() {
        lines = []
        range = ChartRange.full
    }
    
    init(lines: [ChartLineConfig], range: ChartRange) {
        self.lines = lines
        self.range = range
    }
    
    func fullRanged() -> ChartConfig {
        return ChartConfig(lines: lines, range: ChartRange.full)
    }
}

struct ChartLineConfig {
    let key: String
    var visible: Bool
}

struct ChartRange {
    static let full = ChartRange(start: 0, end: 1.0)
    let start: CGFloat
    let end: CGFloat
    var distance: CGFloat { return end - start }
}
