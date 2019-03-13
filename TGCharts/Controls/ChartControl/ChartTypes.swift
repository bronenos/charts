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
    static let full = ChartRange(startPoint: 0, endPoint: 1.0)
    
    let startPoint: CGFloat
    let endPoint: CGFloat
    
    var distance: CGFloat {
        return endPoint - startPoint
    }
}

struct ChartEdges {
    let start: Int
    let end: Int
}
