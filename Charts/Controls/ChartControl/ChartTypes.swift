//
//  ChartTypes.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartConfig: Equatable {
    let standardDistance: CGFloat
    var lines: [ChartLineConfig]
    var range: ChartRange
    var pointer: CGFloat?
    
    init(standardDistance: CGFloat, lines: [ChartLineConfig], range: ChartRange, pointer: CGFloat?) {
        self.standardDistance = standardDistance
        self.lines = lines
        self.range = range
        self.pointer = pointer
    }
    
    func findLine(for key: String) -> ChartLineConfig? {
        for line in lines {
            guard line.key == key else { continue }
            return line
        }
        
        return nil
    }
    
    func withRange(range: ChartRange) -> ChartConfig {
        return ChartConfig(
            standardDistance: standardDistance,
            lines: lines,
            range: range,
            pointer: pointer
        )
    }
    
    static func ==(lhs: ChartConfig, rhs: ChartConfig) -> Bool {
        guard lhs.lines == rhs.lines else { return false }
        guard lhs.range == rhs.range else { return false }
//        guard lhs.pointer == rhs.pointer else { return false }
        return true
    }
}

struct ChartLineConfig: Equatable {
    let key: String
    var visible: Bool
    
    static func ==(lhs: ChartLineConfig, rhs: ChartLineConfig) -> Bool {
        guard lhs.key == rhs.key else { return false }
        guard lhs.visible == rhs.visible else { return false }
        return true
    }
}

struct ChartRange: Equatable {
    static let empty = ChartRange(start: 0, end: 0)
    
    let start: CGFloat
    let end: CGFloat
    
    var distance: CGFloat {
        return end - start
    }
    
    static func ==(lhs: ChartRange, rhs: ChartRange) -> Bool {
        guard lhs.start == rhs.start else { return false }
        guard lhs.end == rhs.end else { return false }
        guard lhs.distance == rhs.distance else { return false }
        return true
    }
}

struct ChartMargins {
    let left: CGFloat
    let right: CGFloat
    var total: CGFloat { return left + right }
}

struct ChartSliceMeta: Equatable {
    let bounds: CGRect
    let config: ChartConfig
    let range: ChartRange
    let totalWidth: CGFloat
    let stepX: CGFloat
    let visibleIndices: Range<Int>
}
