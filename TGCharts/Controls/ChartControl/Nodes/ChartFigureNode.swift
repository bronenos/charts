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
    func setPoints(_ points: [CGPoint])
    func setStrokeColor(_ color: UIColor)
    func setWidth(_ width: CGFloat)
}

class ChartFigureNode: ChartNode, IChartFigureNode {
    private var drawingPoints = [CGPoint]()
    private var strokeColor = UIColor.clear
    private var strokeWidth = CGFloat(0)
    
    func setPoints(_ points: [CGPoint]) {
        drawingPoints = points
    }
    
    func setStrokeColor(_ color: UIColor) {
        strokeColor = color
    }
    
    func setWidth(_ width: CGFloat) {
        strokeWidth = width
    }
    
    override func render(graphics: IGraphics) {
        super.render(graphics: graphics)
        
        graphics.stroke(points: drawingPoints, color: strokeColor, width: strokeWidth)
    }
}
