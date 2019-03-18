//
//  ChartFigureNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartFigureNode: IChartNode {
    var points: [CGPoint] { get set }
    var strokeWidth: CGFloat { get set }
    var strokeColor: UIColor { get set }
}

class ChartFigureNode: ChartNode, IChartFigureNode {
    var points = [CGPoint]()
    var strokeWidth = CGFloat(0)
    var strokeColor = UIColor.clear

    override init(tag: String?) {
        super.init(tag: tag ?? "[figure]")
    }
    
    override func render(graphics: IGraphics) -> Bool {
        guard super.render(graphics: graphics) else { return false }
        
        graphics.stroke(points: points, color: strokeColor, width: strokeWidth)
        return true
    }
}
