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
    var lines: [ChartConfigLine]
    
    init() {
        lines = []
    }
    
    init(lines: [ChartConfigLine]) {
        self.lines = lines
    }
}

struct ChartConfigLine {
    let key: String
    let name: String
    let color: UIColor
    var visible: Bool
}

struct ChartRange {
    static let full = ChartRange(start: 0, end: 1.0)
    
    let start: CGFloat
    let end: CGFloat
    
    var distance: CGFloat {
        return end - start
    }
}

struct ChartEdges {
    let start: Int
    let end: Int
}
