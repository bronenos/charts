//
//  ChartSliderNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartSliderNode: IChartNode {
}

final class ChartSliderNode: ChartNode, IChartSliderNode {
    override func render(graphics: IGraphics) {
        super.render(graphics: graphics)
    }
}
