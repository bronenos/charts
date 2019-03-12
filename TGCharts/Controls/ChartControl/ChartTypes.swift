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
}

struct ChartConfigLine {
    let key: String
    let name: String
    let color: UIColor
    var visible: Bool
}

struct ChartRange {
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
