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
    private let formattingProvider: IFormattingProvider
    
    private let lineNode: ChartNode
    private let dotNodes: [ChartFigureNode]
    private let cloudNode: ChartPointerCloudControl
    
    private var pointing: ChartGraphPointing?
    private var options: ChartPointerOptions = []

    init(chart: Chart, formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        lineNode = ChartNode()
        dotNodes = chart.lines.map(generateDotNode)
        cloudNode = ChartPointerCloudControl()

        super.init(frame: .zero)
        
        lineNode.alpha = 0
        addSubview(lineNode)
        
        dotNodes.forEach { node in
            node.isHidden = true
            addSubview(node)
        }
        
        cloudNode.alpha = 0
        addSubview(cloudNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(pointing: ChartGraphPointing?,
                content: ChartPointerCloudContent?,
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
            pointing: pointing,
            options: options
        )
    }
}

fileprivate struct Layout {
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
    node.strokeWidth = 2
    node.bezierPaths = [path]
    return node
}
