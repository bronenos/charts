//
//  ChartFigureNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

enum ChartFigure {
    case joinedLines
    case separatePoints
    case roundedSquare
}

protocol IChartFigureNode: IChartNode {
    var figure: ChartFigure { get set }
    var points: [CGPoint] { get set }
    var width: CGFloat { get set }
    var color: UIColor { get set }
    var radius: CGFloat { get set }
}

class ChartFigureNode: ChartNode, IChartFigureNode {
    var figure = ChartFigure.joinedLines
    var points = [CGPoint]()
    var width = CGFloat(0)
    var color = UIColor.clear
    var radius = CGFloat(0)

    override init(tag: String?) {
        super.init(tag: tag ?? "[figure]")
    }
    
    override func render(graphics: IGraphics) -> Bool {
        guard super.render(graphics: graphics) else { return false }
        
        switch figure {
        case .joinedLines: renderJoinedLines(graphics: graphics)
        case .separatePoints: renderSeparatePoints(graphics: graphics)
        case .roundedSquare: renderRoundedSquare(graphics: graphics)
        }
        
        return true
    }
    
    private func renderJoinedLines(graphics: IGraphics) {
        graphics.stroke(points: points, color: color, width: width)
    }
    
    private func renderSeparatePoints(graphics: IGraphics) {
        graphics.place(points: points, color: color, width: width)
    }
    
    private func renderRoundedSquare(graphics: IGraphics) {
        let insideLeftPoint = bounds.topLeftPoint + CGVector(dx: 0, dy: radius)
        let insideRightPoint = bounds.bottomRightPoint + CGVector(dx: 0, dy: -radius)
        let outsideLeftPoint = bounds.topLeftPoint + CGVector(dx: radius, dy: 0)
        let outsideRightPoint = bounds.bottomRightPoint + CGVector(dx: -radius, dy: 0)

        let insideLeftArea = CGRect(origin: insideLeftPoint, size: .zero)
        let insideRightArea = CGRect(origin: insideRightPoint, size: .zero)
        graphics.fill(frame: insideLeftArea.union(insideRightArea), color: color)
        
        let outsideLeftArea = CGRect(origin: outsideLeftPoint, size: .zero)
        let outsideRightArea = CGRect(origin: outsideRightPoint, size: .zero)
        graphics.fill(frame: outsideLeftArea.union(outsideRightArea), color: color)
        
        graphics.place(
            points: [
                bounds.topLeftPoint + CGVector(dx: radius, dy: radius),
                bounds.topRightPoint + CGVector(dx: -radius, dy: radius),
                bounds.bottomLeftPoint + CGVector(dx: radius, dy: -radius),
                bounds.bottomRightPoint + CGVector(dx: -radius, dy: -radius),
            ],
            color: color,
            width: radius * 2
        )
    }
}
