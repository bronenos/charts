//
//  ChartNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartNode: class {
    func updateDesign()
}

class ChartNode: UIView, IChartNode {
    func updateDesign() {
    }
}
