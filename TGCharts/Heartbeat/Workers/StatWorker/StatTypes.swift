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
    let axis: StatChartAxis
    let lines: [StatChartLine]
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
