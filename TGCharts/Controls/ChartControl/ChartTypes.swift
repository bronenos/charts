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
    var pointer: CGFloat?
    
    init() {
        lines = []
        range = ChartRange(start: 0, end: 1.0)
        pointer = nil
    }
    
    init(lines: [ChartLineConfig], range: ChartRange, pointer: CGFloat?) {
        self.lines = lines
        self.range = range
        self.pointer = pointer
    }
    
    func fullRanged() -> ChartConfig {
        return ChartConfig(
            lines: lines,
            range: ChartRange(start: 0, end: 1.0),
            pointer: pointer
        )
    }
}

struct ChartLineConfig {
    let key: String
    var visible: Bool
}

struct ChartRange {
    let start: CGFloat
    let end: CGFloat
    var distance: CGFloat { return end - start }
}

struct ChartMargins {
    let left: CGFloat
    let right: CGFloat
    var total: CGFloat { return left + right }
}
