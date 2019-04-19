//
//  NavigatingCalculator.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct NavigatingCalculator {
    let options: ChartNavigatorOptions
    let bounds: CGRect
    let range: ChartRange
    
    var graphStandardWidth: CGFloat {
        return options.caretStandardWidth / options.caretStandardDistance
    }
    
    var graphCurrentX: CGFloat {
        return 0
    }
    
    var graphVirtualCurrentX: CGFloat {
        let rangeCoef = range.start.percent(from: 0, to: 1.0 - options.caretStandardDistance)
        let value = -(graphVirtualCurrentWidth - bounds.width) * rangeCoef
        return value
    }
    
    var graphCurrentWidth: CGFloat {
        return bounds.width
    }
    
    var graphVirtualCurrentWidth: CGFloat {
        let rangeCoef = range.distance.percent(from: options.caretStandardDistance, to: 1.0)
        return rangeCoef.triangulate(from: graphStandardWidth, to: bounds.width)
    }
    
    var graphCurrentRange: ChartRange {
        let rangeCoef = range.start.percent(from: 0, to: 1.0 - range.distance)
        let distance = range.distance * (bounds.width / caretCurrentWidth)
        let start = (1.0 - distance) * rangeCoef
        return ChartRange(start: start, end: start + distance)
    }
    
    var caretCurrentX: CGFloat {
        let rangeCoef = range.start.percent(from: 0, to: 1.0 - range.distance)
        let result = (bounds.width - caretCurrentWidth) * rangeCoef
        return result
    }
    
    var caretCurrentWidth: CGFloat {
        let standardWidth = options.caretStandardWidth
        let standardDistance = options.caretStandardDistance
        let distanceCoef = range.distance.percent(from: standardDistance, to: 1.0)
        return standardWidth + (bounds.width - standardWidth) * distanceCoef
    }
}
