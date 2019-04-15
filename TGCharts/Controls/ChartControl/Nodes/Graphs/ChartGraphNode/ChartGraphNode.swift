//
//  ChartGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartGraphPointing {
    let pointer: CGFloat
    let index: Int
    let coordX: CGFloat?
    let points: [CGPoint]
    
    init() {
        pointer = 0
        index = 0
        coordX = nil
        points = []
    }
    
    init(pointer: CGFloat, index: Int, coordX: CGFloat?, points: [CGPoint]) {
        self.pointer = pointer
        self.index = index
        self.coordX = coordX
        self.points = points
    }
}

protocol IChartGraphNode {
    var container: IChartGraphContainer? { get set }
    func update(config: ChartConfig, shouldUpdateEye: Bool, duration: TimeInterval)
    func calculatePointing(pointer: CGFloat, rounder: (CGFloat) -> CGFloat) -> ChartGraphPointing
}

struct ChartGraphEye: Equatable {
    let edges: UIEdgeInsets
    let scaleFactor: CGFloat
}

struct CalculatePointsResult {
    let range: ChartRange
    let context: ChartEyeOperationContext
    let points: [String: [CGPoint]]
    let eyes: [ChartGraphEye]
}

struct CalculateEyesResult {
    let context: ChartEyeOperationContext
    let edges: [ChartRange]
    let eyes: [ChartGraphEye]
}

class ChartGraphNode: ChartNode, IChartGraphNode {
    weak var container: IChartGraphContainer?
    
    let chart: Chart
    let enableControls: Bool
    let formattingProvider: IFormattingProvider
    let localeProvider: ILocaleProvider
    
    private(set) var config: ChartConfig
    private(set) var eyes: [ChartGraphEye]

    let figuresContainer = ChartNode()
    var figureNodes = [String: ChartFigureNode]()
    var orderedNodes = [ChartFigureNode]()

    private(set) var lastMeta: ChartSliceMeta?
    let calculationQueue = OperationQueue()
    var cachedPoints = [String: [CGPoint]]()
    var cachedEyesContext: ChartEyeOperationContext?

    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, localeProvider: ILocaleProvider, enableControls: Bool) {
        self.chart = chart
        self.enableControls = enableControls
        self.formattingProvider = formattingProvider
        self.localeProvider = localeProvider
        self.config = config
        self.eyes = chart.axis.indices.map { _ in ChartGraphEye(edges: .zero, scaleFactor: 1.0) }
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        
        calculationQueue.maxConcurrentOperationCount = 1
        calculationQueue.qualityOfService = .userInteractive
        
        figuresContainer.tag = ChartControlTag.graph.rawValue
        addSubview(figuresContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var frame: CGRect {
        didSet {
            guard frame.size != oldValue.size else { return }
            discardCache()
        }
    }
    
    var numberOfSteps: Int {
        abort()
    }
    
    final func configure(figure: ChartFigure, block: @escaping (Int, ChartFigureNode, ChartLine) -> Void) {
        orderedNodes.forEach { node in
            node.removeFromSuperview()
        }
        
        orderedNodes.removeAll()
        figureNodes.removeAll()

        chart.lines.enumerated().forEach { index, line in
            let node = ChartFigureNode(figure: figure)
            node.isUserInteractionEnabled = false
            block(index, node, line)
            
            orderedNodes.append(node)
            figureNodes[line.key] = node
            figuresContainer.addSubview(node)
        }
    }
    
    func update(config: ChartConfig, shouldUpdateEye: Bool, duration: TimeInterval) {
        if shouldReset(newConfig: config, oldConfig: self.config) {
            discardCache()
        }
        
        self.config = config
        
        if shouldUpdateEye {
            enqueueRecalculation(duration: duration)
        }
        else {
            if let context = cachedEyesContext {
                updatePointer(
                    eyes: eyes,
                    valueEdges: context.valueEdges,
                    duration: duration
                )
            }
            else {
                enqueueRecalculation(duration: duration)
            }
        }
    }
    
    final func calculateIndex(pointer: CGFloat, rounder: (CGFloat) -> CGFloat) -> Int? {
        guard let firstFigureNode = orderedNodes.first else {
            return nil
        }
        
        let originalX = firstFigureNode.convertEffectiveToOriginal(
            x: bounds.width * pointer
        )
        
        let stepX = bounds.width / CGFloat(numberOfSteps)
        let originalIndex = Int(rounder(originalX / stepX))
        let normalizedIndex = between(value: originalIndex, minimum: 0, maximum: chart.axis.count - 1)
        
        let normalizedPoint = CGPoint(x: CGFloat(normalizedIndex) * stepX, y: 0)
        let effectivePoint = firstFigureNode.convertOriginalToEffective(point: normalizedPoint)
        
        if effectivePoint.x > bounds.maxX {
            return normalizedIndex - 1
        }
        else if effectivePoint.x < bounds.minX {
            return normalizedIndex + 1
        }
        else {
            return normalizedIndex
        }
    }
    
    final func calculatePointing(pointer: CGFloat, rounder: (CGFloat) -> CGFloat) -> ChartGraphPointing {
        guard let index = calculateIndex(pointer: pointer, rounder: rounder) else {
            return ChartGraphPointing()
        }
        
        return ChartGraphPointing(
            pointer: pointer,
            index: index,
            coordX: orderedNodes.first.flatMap { node in
                let stepX = bounds.width / CGFloat(numberOfSteps)
                return node.convertOriginalToEffective(x: CGFloat(index) * stepX)
            },
            points: calculatePoints(forIndex: index)
        )
    }
    
    override func discardCache() {
        super.discardCache()
        cachedEyesContext = nil
        lastMeta = nil
    }
    
    func shouldReset(newConfig: ChartConfig, oldConfig: ChartConfig) -> Bool {
        abort()
    }
    
    func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                          duration: TimeInterval,
                                          completion: @escaping (CalculatePointsResult) -> Void) -> ChartPointsOperation {
        abort()
    }

    func obtainEyesCalculationOperation(meta: ChartSliceMeta,
                                        context: ChartEyeOperationContext,
                                        duration: TimeInterval,
                                        completion: @escaping (CalculateEyesResult) -> Void) -> ChartEyesOperation {
        abort()
    }

    func updateChart(points: [String: [CGPoint]]) {
        self.cachedPoints = points
    }
    
    func updateVisibility(config: ChartConfig, duration: TimeInterval) {
        self.config = config
    }
    
    func updateEyes(_ eyes: [ChartGraphEye], edges: [ChartRange], duration: TimeInterval) {
        self.eyes = eyes
        
        for (node, eye) in zip(orderedNodes, eyes) {
            node.setEye(insets: eye.edges, scale: eye.scaleFactor, duration: duration)
        }
    }
    
    func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        abort()
    }
        
    func updatePointer(eyes: [ChartGraphEye],
                       valueEdges: [ChartRange],
                       duration: TimeInterval) {
        abort()
    }
    
    func calculatePoints(forIndex index: Int) -> [CGPoint] {
        return zip(chart.lines, orderedNodes).map { line, node in
            let originalPoint = cachedPoints[line.key]?[index] ?? .zero
            let value = node.convertOriginalToEffective(point: originalPoint)
            return value
        }
    }
    
    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.primaryBackground)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 300)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        figuresContainer.frame = bounds
        figuresContainer.subviews.forEach { $0.frame = bounds }
    }
    
    private func enqueueRecalculation(duration: TimeInterval) {
        guard bounds.size != .zero else { return }
        
        let meta = chart.obtainMeta(config: config, bounds: bounds)
        guard meta.range.distance > 0 else { return }
        
        if let eyesContext = cachedEyesContext {
            let operation = obtainEyesCalculationOperation(
                meta: meta,
                context: eyesContext,
                duration: duration,
                completion: { [weak self] result in
                    guard let `self` = self else { return }
                    self.cachedEyesContext = result.context
                    
                    self.updateEyes(
                        result.eyes,
                        edges: result.edges,
                        duration: duration
                    )
                    
                    self.updateGuides(
                        edges: result.edges,
                        duration: duration
                    )
                    
                    self.updatePointer(
                        eyes: result.eyes,
                        valueEdges: result.context.valueEdges,
                        duration: duration
                    )
                }
            )
            
            if calculationQueue.operations.isEmpty {
                calculationQueue.addOperation(operation)
            }
        }
        else if meta != lastMeta {
            lastMeta = meta
            
            let operation = obtainPointsCalculationOperation(
                meta: meta,
                duration: duration,
                completion: { [weak self] result in
                    guard let `self` = self else { return }
                    self.cachedEyesContext = result.context
                    
                    self.updateChart(
                        points: result.points
                    )
                    
                    self.updateEyes(
                        result.eyes,
                        edges: result.context.totalEdges,
                        duration: duration
                    )
                    
                    self.updateGuides(
                        edges: result.context.lineEdges,
                        duration: duration
                    )
                }
            )
            
            if let _ = cachedEyesContext {
                if calculationQueue.operations.isEmpty {
                    calculationQueue.addOperation(operation)
                }
            }
            else {
                operation.main()
            }
        }
        else {
            updatePointer(
                eyes: [],
                valueEdges: [],
                duration: duration
            )
        }
    }
}
