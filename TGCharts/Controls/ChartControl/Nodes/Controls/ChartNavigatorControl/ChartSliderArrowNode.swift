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
    
    init(direction: ChartSliderArrowDirection) {
        self.direction = direction
        
        super.init(figure: .joinedLines)
        
        width = 2
        
        switch direction {
        case .left: tag = ChartControlTag.leftArrow.rawValue
        case .right: tag = ChartControlTag.rightArrow.rawValue
        }
        
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    override var frame: CGRect {
        didSet { points = calculatePoints() }
    }
    
    override func updateDesign() {
        super.updateDesign()
        strokeColor = DesignBook.shared.color(.sliderForeground)
    }
    
    private func calculatePoints() -> [CGPoint] {
        let mult: CGFloat
        switch direction {
        case .left: mult = 1
        case .right: mult = -1
        }
        
        return [
            bounds.offsetBy(dx: 1 * mult, dy: 5).center,
            bounds.offsetBy(dx: -1 * mult, dy: 0).center,
            bounds.offsetBy(dx: 1 * mult, dy: -5).center
        ]
    }
}
