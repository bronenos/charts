//
//  ChartPointerContainer.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartPointerOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    static let line = ChartPointerOptions(rawValue: 1 << 0)
    static let dots = ChartPointerOptions(rawValue: 1 << 1)
    static let anchor = ChartPointerOptions(rawValue: 1 << 2)
    static let closely = ChartPointerOptions(rawValue: 1 << 3)
    static let disclosable = ChartPointerOptions(rawValue: 1 << 4)
}

protocol IChartPointerContainer: IChartNode {
    func update(pointing: ChartGraphPointing?,
                content: ChartPointerCloudContent?,
                options: ChartPointerOptions,
                duration: TimeInterval)
}

final class ChartPointerContainer: ChartNode, IChartPointerContainer {
    private let chart: Chart
    private let formattingProvider: IFormattingProvider
    
    private let lineNode: ChartNode
    private var orderedDotNodes = [ChartFigureNode]()
    private var dotNodes = [String: ChartFigureNode]()
    private let cloudNode: ChartPointerCloudControl
    
    private var pointing: ChartGraphPointing?
    private var options: ChartPointerOptions = []

    init(chart: Chart, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.formattingProvider = formattingProvider
        
        lineNode = ChartNode()
        cloudNode = ChartPointerCloudControl()

        super.init(frame: .zero)
        
        lineNode.alpha = 0
        addSubview(lineNode)
        
        cloudNode.alpha = 0
        addSubview(cloudNode)
        
        updateDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(pointing: ChartGraphPointing?,
                content: ChartPointerCloudContent?,
                options: ChartPointerOptions,
                duration: TimeInterval) {
        if let points = pointing?.points {
            lineNode.backgroundColor = DesignBook.shared.color(.chartGridStroke)
            
            for (line, node) in zip(chart.lines, orderedDotNodes) {
                if !options.contains(.dots) {
                    node.isHidden = true
                }
                else if let _ = points[line.key] {
                    node.isHidden = false
                }
                else {
                    node.isHidden = true
                }
            }
            
            lineNode.isHidden = !options.contains(.line)
        }
        else {
            for node in orderedDotNodes {
                node.isHidden = true
            }
            
            lineNode.isHidden = true
        }
        
        if let content = content {
            cloudNode.populate(content: content)
        }
        
        if let _ = pointing, let _ = self.pointing {
            self.pointing = pointing
            self.options = options
            
            layout(duration: duration)
        }
        else if let _ = pointing {
            self.pointing = pointing
            self.options = options
            
            layout(duration: 0)
            
            cloudNode.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            cloudNode.alpha = 0
            lineNode.alpha = 0
            
            UIView.animate(withDuration: duration) { [weak self] in
                self?.cloudNode.transform = .identity
                self?.cloudNode.alpha = 1.0
                self?.lineNode.alpha = 1.0
            }
        }
        else if let _ = self.pointing {
            self.pointing = pointing
            self.options = options
            
            layout(duration: 0)
            
            cloudNode.transform = .identity
            cloudNode.alpha = 1.0
            lineNode.alpha = 1.0
            
            UIView.animate(withDuration: duration) { [weak self] in
                self?.cloudNode.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                self?.cloudNode.alpha = 0
                self?.lineNode.alpha = 0
            }
        }
        else {
            self.pointing = pointing
            self.options = options
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        
        orderedDotNodes.forEach { $0.removeFromSuperview() }
        orderedDotNodes = chart.lines.map { generateDotNode(chart: chart, line: $0) }
        zip(chart.lines, orderedDotNodes).forEach { line, node in
            node.isHidden = true
            addSubview(node)
            dotNodes[line.key] = node
        }
        
        cloudNode.updateDesign()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let pointing = pointing {
            let layout = getLayout(size: bounds.size, pointing: pointing)
            lineNode.frame = layout.lineNodeFrame
            zip(orderedDotNodes, layout.dotNodeFrames).forEach { node, frame in node.frame = frame }
            cloudNode.layer.bounds = layout.cloudNodeBounds
            cloudNode.layer.position = layout.cloudNodePosition
        }
    }
    
    private func getLayout(size: CGSize, pointing: ChartGraphPointing) -> Layout {
        return Layout(
            chart: chart,
            bounds: CGRect(origin: .zero, size: size),
            dotNodes: orderedDotNodes,
            cloudNode: cloudNode,
            pointing: pointing,
            options: options
        )
    }
}

fileprivate struct Layout {
    let chart: Chart
    let bounds: CGRect
    let dotNodes: [ChartFigureNode]
    let cloudNode: ChartPointerCloudControl
    let pointing: ChartGraphPointing
    let options: ChartPointerOptions
    
    private let cloudOffscreen = CGFloat(10)
    private let cloudExtraMove = CGFloat(20)

    var lineNodeFrame: CGRect {
        if let pointedX = pointing.coordX {
            return CGRect(x: pointedX, y: 0, width: 1, height: bounds.height)
        }
        else {
            return .zero
        }
    }
    
    var dotNodeFrames: [CGRect] {
        return chart.lines.map { line in
            guard let point = pointing.points[line.key] else { return .zero }
            return CGRect(origin: point, size: .zero)
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
    
    private var cloudTopMargin: CGFloat {
        return options.contains(.closely) ? 0 : 5
    }

    private var cloudNodeFrame: CGRect {
        let size = cloudNode.sizeThatFits(.zero)
        
        let leftX = between(
            value: (bounds.width * pointing.pointer) - size.width * 0.5,
            minimum: -cloudOffscreen,
            maximum: bounds.width + cloudOffscreen - size.width
        )
        
        let baseFrame = CGRect(
            x: leftX,
            y: cloudTopMargin,
            width: size.width,
            height: size.height
        )
        
        guard let topDotFrame = dotNodeFrames.sorted(by: { $0.minY < $1.minY }).first else {
            return baseFrame
        }
        
        guard topDotFrame.minY < baseFrame.maxY else {
            return baseFrame
        }
        
        if topDotFrame.midX > bounds.midX {
            let leftX = topDotFrame.minX - cloudExtraMove - size.width
            return CGRect(x: leftX, y: cloudTopMargin, width: size.width, height: size.height)
        }
        else {
            let leftX = topDotFrame.maxX + cloudExtraMove
            return CGRect(x: leftX, y: cloudTopMargin, width: size.width, height: size.height)
        }
    }
}

fileprivate func generateDotNode(chart: Chart, line: ChartLine) -> ChartFigureNode {
    let path = UIBezierPath(
        arcCenter: .zero,
        radius: 3,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
    )
    
    let node = ChartFigureNode(figure: .nestedBezierPaths)
    node.strokeColor = DesignBook.shared.color(chart: chart, key: .line(line.colorKey))
    node.fillColor = DesignBook.shared.color(.primaryBackground)
    node.strokeWidth = 2
    node.bezierPaths = [path]
    return node
}
