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
    case nestedBezierPaths
}

protocol IChartFigureNode: IChartNode {
    var figure: ChartFigure { get set }
    var points: [CGPoint] { get set }
    var bezierPaths: [UIBezierPath] { get set }
    var width: CGFloat { get set }
    var strokeColor: UIColor { get set }
    var fillColor: UIColor { get set }
    var radius: CGFloat { get set }
    func overwriteNextAnimation(duration: TimeInterval)
}

class ChartFigureNode: ChartNode, IChartFigureNode {
    private let shapeLayer = CAShapeLayer()
    
    private let standardAnimationDuration = TimeInterval(0.075)
    private var nextAnimationDuration: TimeInterval?

    init(figure: ChartFigure) {
        super.init(frame: .zero)
        
        self.figure = figure
        
        layer.addSublayer(shapeLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    var figure = ChartFigure.joinedLines {
        didSet {
            guard figure != oldValue else { return }
            update()
        }
    }
    
    override var frame: CGRect {
        didSet {
            guard frame.size != oldValue.size else { return }
            update()
        }
    }
    
    var points = [CGPoint]() {
        didSet {
            guard points != oldValue else { return }
            update()
        }
    }
    
    var bezierPaths = [UIBezierPath]() {
        didSet {
            guard bezierPaths != oldValue else { return }
            update()
        }
    }
    
    var width = CGFloat(0) {
        didSet {
            guard width != oldValue else { return }
            update()
        }
    }
    
    var strokeColor = UIColor.clear {
        didSet {
            guard strokeColor != oldValue else { return }
            update()
        }
    }
    
    var fillColor = UIColor.clear {
        didSet {
            guard fillColor != oldValue else { return }
            update()
        }
    }
    
    var radius = CGFloat(0) {
        didSet {
            guard radius != oldValue else { return }
            update()
        }
    }
    
    func overwriteNextAnimation(duration: TimeInterval) {
        nextAnimationDuration = duration
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shapeLayer.frame = layer.bounds
    }
    
    private func update() {
        switch figure {
        case .joinedLines: renderJoinedLines()
        case .separatePoints: renderSeparatePoints()
        case .roundedSquare: renderRoundedSquare()
        case .nestedBezierPaths: renderNestedBezierPaths()
        }
    }
    
    private func renderJoinedLines() {
        var restPoints = points
        guard !restPoints.isEmpty else { return }
        
        let firstPoint = restPoints.removeFirst()
        guard !restPoints.isEmpty else { return }

        let bezierPath = UIBezierPath()
        bezierPath.lineWidth = width
        bezierPath.lineJoinStyle = .round
        bezierPath.lineCapStyle = .round
        bezierPath.move(to: firstPoint)
        restPoints.forEach(bezierPath.addLine)
        
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = resolvedAnimationDuration
        animation.fromValue = shapeLayer.presentation()?.path
        animation.toValue = bezierPath.cgPath
        
        shapeLayer.lineWidth = width
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.lineJoin = .round
        shapeLayer.lineCap = .round
        shapeLayer.path = bezierPath.cgPath
        shapeLayer.add(animation, forKey: animation.keyPath)
        CATransaction.commit()
    }
    
    private func renderSeparatePoints() {
        let bezierPath = UIBezierPath()
        
        points.forEach { point in
            let offset = width * 0.5
            let rect = CGRect(x: point.x, y: point.y, width: 0, height: 0).insetBy(dx: offset, dy: offset)
            let bezierSubpath = UIBezierPath(roundedRect: rect, cornerRadius: offset)
            bezierPath.append(bezierSubpath)
        }
        
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.path = bezierPath.cgPath
    }
    
    private func renderRoundedSquare() {
        let bezierPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius)
        
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.path = bezierPath.cgPath
    }
    
    private func renderNestedBezierPaths() {
        var restPaths = bezierPaths
        guard !restPaths.isEmpty else { return }
        
        let firstPath = restPaths.removeFirst()
        firstPath.usesEvenOddFillRule = true
        restPaths.forEach(firstPath.append)
        
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = width
        shapeLayer.fillRule = .evenOdd
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.path = firstPath.cgPath
    }
    
    private var resolvedAnimationDuration: TimeInterval {
        defer { nextAnimationDuration = nil }
        return nextAnimationDuration ?? standardAnimationDuration
    }
}
