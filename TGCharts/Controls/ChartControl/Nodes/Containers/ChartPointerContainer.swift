//
//  ChartPointerContainer.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartPointerContainer: IChartNode {
    func update(chart: Chart,
                config: ChartConfig,
                pointing: ChartGraphPointing?,
                options: ChartPointerOptions,
                duration: TimeInterval)
}

final class ChartPointerContainer: ChartNode, IChartPointerContainer {
    private let lineNode: ChartNode
    private let dotNodes: [ChartFigureNode]
    private let cloudNode: ChartPointerCloudNode
    
    private var pointing: ChartGraphPointing?

    init(chart: Chart, formattingProvider: IFormattingProvider) {
        lineNode = ChartNode()
        dotNodes = chart.lines.map(generateDotNode)
        cloudNode = ChartPointerCloudNode(formattingProvider: formattingProvider)

        super.init(frame: .zero)
        
        addSubview(lineNode)
        dotNodes.forEach(addSubview)
        addSubview(cloudNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(chart: Chart,
                config: ChartConfig,
                pointing: ChartGraphPointing?,
                options: ChartPointerOptions,
                duration: TimeInterval) {
        if let _ = pointing {
            lineNode.backgroundColor = DesignBook.shared.color(.chartPointerFocusedLineStroke)
            
            for node in dotNodes { node.isHidden = !options.contains(.dots) }
            lineNode.isHidden = !options.contains(.line)
        }
        else {
            for node in dotNodes { node.isHidden = true }
            lineNode.isHidden = true
        }
        
        if let pointing = pointing {
            let date = chart.axis[pointing.index].date
            let lines = chart.visibleLines(config: config)
            cloudNode.setDate(date, lines: lines, index: pointing.index)
        }
        
        if let _ = pointing, let _ = self.pointing {
            self.pointing = pointing
            layout(duration: duration)
        }
        else if let _ = pointing {
            self.pointing = pointing
            layout(duration: 0)
            
            cloudNode.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            cloudNode.alpha = 0
            
            UIView.animate(withDuration: duration) { [unowned self] in
                self.cloudNode.transform = .identity
                self.cloudNode.alpha = 1.0
            }
        }
        else if let _ = self.pointing {
            self.pointing = pointing
            layout(duration: 0)
            
            cloudNode.transform = .identity
            cloudNode.alpha = 1.0
            
            UIView.animate(withDuration: duration) { [unowned self] in
                self.cloudNode.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                self.cloudNode.alpha = 0
            }
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        cloudNode.updateDesign()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let pointing = pointing {
            let layout = getLayout(size: bounds.size, pointing: pointing)
            lineNode.frame = layout.lineNodeFrame
            zip(dotNodes, layout.dotNodeFrames).forEach { node, frame in node.frame = frame }
            cloudNode.layer.bounds = layout.cloudNodeBounds
            cloudNode.layer.position = layout.cloudNodePosition
        }
    }
    
    private func getLayout(size: CGSize, pointing: ChartGraphPointing) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            dotNodes: dotNodes,
            cloudNode: cloudNode,
            pointing: pointing
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let dotNodes: [ChartFigureNode]
    let cloudNode: ChartPointerCloudNode
    let pointing: ChartGraphPointing
    
    private let cloudOffscreen = CGFloat(10)
    private let cloudExtraMove = CGFloat(10)

    var lineNodeFrame: CGRect {
        if let pointedX = pointing.points.first?.x {
            return CGRect(x: pointedX, y: 0, width: 1, height: bounds.height)
        }
        else {
            return .zero
        }
    }
    
    var dotNodeFrames: [CGRect] {
        return pointing.points.map { point in
            CGRect(origin: point, size: .zero)
        }
    }
    
    var cloudNodeBounds: CGRect {
        let size = cloudNodeFrame.size
        return CGRect(origin: .zero, size: size)
    }
    
    var cloudNodePosition: CGPoint {
        let midX = cloudNodeFrame.midX
        let midY = cloudNodeFrame.midY
        return CGPoint(x: midX, y: midY)
    }
    
    private var cloudNodeFrame: CGRect {
        let size = cloudNode.sizeThatFits(.zero)
        let leftX = (bounds.width + cloudOffscreen * 2 - size.width) * pointing.pointer - cloudOffscreen
        let baseFrame = CGRect(x: leftX, y: 0, width: size.width, height: size.height)
        
        guard let dotPoint = dotNodeFrames.first else {
            return baseFrame
        }
        
        guard dotPoint.minY < baseFrame.maxY else {
            return baseFrame
        }
        
        if dotPoint.midX > bounds.midX {
            let leftX = dotPoint.minX - cloudExtraMove - size.width
            return CGRect(x: leftX, y: 0, width: size.width, height: size.height)
        }
        else {
            let leftX = dotPoint.maxX + cloudExtraMove
            return CGRect(x: leftX, y: 0, width: size.width, height: size.height)
        }
    }
}

fileprivate func generateDotNode(line: ChartLine) -> ChartFigureNode {
    let path = UIBezierPath(
        arcCenter: .zero,
        radius: 3,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
    )
    
    let node = ChartFigureNode(figure: .nestedBezierPaths)
    node.strokeColor = line.color
    node.fillColor = DesignBook.shared.color(.primaryBackground)
    node.bezierPaths = [path]
    node.width = 2
    return node
}
