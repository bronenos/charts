//
//  ChartSliderArrowNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum ChartSliderArrowDirection {
    case left
    case right
}

protocol IChartSliderArrowNode: IChartNode {
}

final class ChartSliderArrowNode: ChartFigureNode, IChartSliderArrowNode {
    let direction: ChartSliderArrowDirection
    
    init(tag: String?, direction: ChartSliderArrowDirection) {
        self.direction = direction
        
        super.init(tag: tag ?? "[slider-arrow]")
        
        width = 1
    }
    
    override var frame: CGRect {
        didSet { points = calculatePoints() }
    }
    
    override var foregroundColor: UIColor {
        didSet { color = foregroundColor }
    }
    
    private func calculatePoints() -> [CGPoint] {
        let mult: CGFloat
        switch direction {
        case .left: mult = 1
        case .right: mult = -1
        }
        
        return [
            bounds.offsetBy(dx: 1 * mult, dy: 3).center,
            bounds.offsetBy(dx: -1 * mult, dy: 0).center,
            bounds.offsetBy(dx: 1 * mult, dy: -3).center
        ]
    }
}
