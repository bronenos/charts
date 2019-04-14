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
    case filledPaths
}

protocol IChartFigureNode: IChartNode {
    var figure: ChartFigure { get set }
    var points: [CGPoint] { get set }
    var bezierPaths: [UIBezierPath] { get set }
    var width: CGFloat { get set }
    var strokeColor: UIColor { get set }
    var fillColor: UIColor { get set }
    var radius: CGFloat { get set }
    func updateEye(_ eye: UIEdgeInsets?, duration: TimeInterval)
}

class ChartFigureNode: ChartNode, IChartFigureNode {
    private let shapeLayer = CAShapeLayer()
    private var rootBezierPath = UIBezierPath()
    
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
            updateFigure()
        }
    }
    
    override var frame: CGRect {
        didSet {
            guard frame.size != oldValue.size else { return }
            updateFigure()
        }
    }
    
    var points = [CGPoint]() {
        didSet {
            guard points != oldValue else { return }
            updateFigure()
        }
    }
    
    var bezierPaths = [UIBezierPath]() {
        didSet {
            guard bezierPaths != oldValue else { return }
            updateFigure()
        }
    }
    
    var width = CGFloat(0) {
        didSet {
            guard width != oldValue else { return }
            updateFigure()
        }
    }
    
    var strokeColor = UIColor.clear {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }
    
    var fillColor = UIColor.clear {
        didSet {
            shapeLayer.fillColor = fillColor.cgColor
        }
    }
    
    var radius = CGFloat(0) {
        didSet {
            guard radius != oldValue else { return }
            updateFigure()
        }
    }
    
    func updateEye(_ eye: UIEdgeInsets?, duration: TimeInterval) {
        let path: CGPath
        if let eye = eye {
            var targetTransform = CGAffineTransform.identity
            
            let scaleX = 1.0 / (eye.right - eye.left)
            let scaleY = 1.0 / (eye.top - eye.bottom)
            targetTransform = targetTransform.scaledBy(x: scaleX, y: scaleY)
            
            let moveX = -(bounds.width * eye.left)
            let moveY = -(bounds.height * (1.0 - eye.top))
            targetTransform = targetTransform.translatedBy(x: moveX, y: moveY)
            
            let transformedBezierPath = UIBezierPath(cgPath: rootBezierPath.cgPath)
            transformedBezierPath.apply(targetTransform)
            path = transformedBezierPath.cgPath
        }
        else {
            path = rootBezierPath.cgPath
        }

        if duration > 0 {
            CATransaction.begin()
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = duration
            animation.fromValue = shapeLayer.presentation()?.path
            animation.toValue = path
            
            shapeLayer.path = path
            shapeLayer.add(animation, forKey: animation.keyPath)
            CATransaction.commit()
        }
        else {
            shapeLayer.path = path
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shapeLayer.frame = layer.bounds
    }
    
    private func updateFigure() {
        rootBezierPath.removeAllPoints()
        
        switch figure {
        case .joinedLines: renderJoinedLines()
        case .separatePoints: renderSeparatePoints()
        case .roundedSquare: renderRoundedSquare()
        case .nestedBezierPaths: renderNestedBezierPaths()
        case .filledPaths: renderFilledPaths()
        }
    }
    
    private func renderJoinedLines() {
        var restPoints = points
        guard !restPoints.isEmpty else { return }
        
        let firstPoint = restPoints.removeFirst()
        guard !restPoints.isEmpty else { return }

        rootBezierPath.move(to: firstPoint)
        restPoints.forEach(rootBezierPath.addLine)
        
        shapeLayer.lineWidth = width
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.lineJoin = .round
        shapeLayer.lineCap = .round
        shapeLayer.path = rootBezierPath.cgPath
    }
    
    private func renderSeparatePoints() {
        points.forEach { point in
            let offset = width * 0.5
            let rect = CGRect(x: point.x, y: point.y, width: 0, height: 0).insetBy(dx: offset, dy: offset)
            let bezierSubpath = UIBezierPath(roundedRect: rect, cornerRadius: offset)
            rootBezierPath.append(bezierSubpath)
        }
        
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.path = rootBezierPath.cgPath
    }
    
    private func renderRoundedSquare() {
        rootBezierPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius)
        
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.path = rootBezierPath.cgPath
    }
    
    private func renderNestedBezierPaths() {
        var restPaths = bezierPaths
        guard !restPaths.isEmpty else { return }
        
        rootBezierPath = restPaths.removeFirst()
        restPaths.forEach(rootBezierPath.append)
        
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = width
        shapeLayer.fillRule = .evenOdd
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.fillRule = .evenOdd
        shapeLayer.path = rootBezierPath.cgPath
    }
    
    private func renderFilledPaths() {
        rootBezierPath = UIBezierPath()
        bezierPaths.forEach(rootBezierPath.append)
        
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.path = rootBezierPath.cgPath
    }
}
