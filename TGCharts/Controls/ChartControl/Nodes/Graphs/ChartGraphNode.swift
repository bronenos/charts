//
//  ChartGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGraphNode {
    var container: IChartGraphContainer? { get set }
    func update(config: ChartConfig, duration: TimeInterval)
}

struct CalculatePointsResult {
    let range: ChartRange
    let edges: [ChartRange]
    let points: [String: [CGPoint]]
}

struct CalculateFocusResult {
    let edges: [ChartRange]
    let focus: UIEdgeInsets
}

class ChartGraphNode: ChartNode, IChartGraphNode {
    weak var container: IChartGraphContainer?
    
    let chart: Chart
    private(set) var config: ChartConfig

    let figuresContainer = ChartNode()
    var figureNodes = [String: ChartFigureNode]()
    var orderedNodes = [ChartFigureNode]()

    private var lastMeta: ChartSliceMeta?
    private var hasCalculatedPoints = false
    
    let calculationQueue = OperationQueue()
    var cachedPointsResult: CalculatePointsResult?
    var cachedFocusResult: CalculateFocusResult?

    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = config
        
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
            hasCalculatedPoints = false
        }
    }
    
    final func configure(figure: ChartFigure, block: @escaping (Int, ChartFigureNode, ChartLine) -> Void) {
        orderedNodes.removeAll()
        chart.lines.enumerated().forEach { index, line in
            let node = ChartFigureNode(figure: figure)
            block(index, node, line)
            
            orderedNodes.append(node)
            figureNodes[line.key] = node
            figuresContainer.addSubview(node)
        }
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        
        if duration > 0 {
            figureNodes.values.forEach { $0.overwriteNextAnimation(duration: duration) }
        }
        
        enqueueRecalculation(duration: duration)
    }
    
    func obtainPointsCalculationOperation(meta: ChartSliceMeta,
                                          date: Date,
                                          duration: TimeInterval,
                                          completion: @escaping (CalculatePointsResult) -> Void) -> CalculatePointsOperation {
        abort()
    }

    func updateChart(_ chart: Chart, meta: ChartSliceMeta, edges: [ChartRange], duration: TimeInterval) {
        abort()
    }
    
    func obtainFocusCalculationOperation(meta: ChartSliceMeta,
                                         edges: [ChartRange],
                                         duration: TimeInterval,
                                         completion: @escaping (CalculateFocusResult) -> Void) -> CalculateFocusOperation {
        abort()
    }
    
    func updateFocus(_ focus: UIEdgeInsets, edges: [ChartRange], duration: TimeInterval) {
        abort()
    }
    
    func updateGuides(edges: [ChartRange], duration: TimeInterval) {
        abort()
    }
        
    func updatePointer(meta: ChartSliceMeta) {
        abort()
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
        enqueueRecalculation(duration: 0)
    }
    
    private func enqueueRecalculation(duration: TimeInterval) {
        guard bounds.size != .zero else { return }
        
        let meta = chart.obtainMeta(config: config, bounds: bounds)
        guard meta.range.distance > 0 else { return }
        
        if let pointsResult = cachedPointsResult, hasCalculatedPoints {
            let operation = obtainFocusCalculationOperation(
                meta: meta,
                edges: pointsResult.edges,
                duration: duration,
                completion: { [weak self] result in
                    guard let `self` = self else { return }
                    self.cachedFocusResult = result
                    
                    self.updateFocus(result.focus, edges: result.edges, duration: duration)
                    self.updateGuides(edges: result.edges, duration: duration)
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
                date: Date(),
                duration: duration,
                completion: { [weak self] result in
                    guard let `self` = self else { return }
                    self.cachedPointsResult = result
                    self.hasCalculatedPoints = true
                    
                    self.updateChart(self.chart, meta: meta, edges: result.edges, duration: duration)
                    self.updateGuides(edges: result.edges, duration: duration)
                }
            )
            
            if let _ = cachedPointsResult {
                if calculationQueue.operations.isEmpty {
                    calculationQueue.addOperation(operation)
                }
            }
            else {
                operation.main()
            }
        }
        else {
            updatePointer(meta: meta)
        }
    }
}

class CalculateOperation<Type, Source>: Operation {
    let chart: Chart
    let config: ChartConfig
    let meta: ChartSliceMeta
    let bounds: CGRect
    let source: Source
    let completion: ((Type) -> Void)
    
    private let callerQueue = OperationQueue.current ?? .main
    
    init(chart: Chart,
         config: ChartConfig,
         meta: ChartSliceMeta,
         bounds: CGRect,
         source: Source,
         completion: @escaping ((Type) -> Void)) {
        self.chart = chart
        self.config = config
        self.meta = meta
        self.bounds = bounds
        self.source = source
        self.completion = completion
    }
    
    func calculateResult() -> Type {
        abort()
    }
    
    override func main() {
        let result = calculateResult()
        
        if Thread.isMainThread {
            completion(result)
        }
        else {
            let block = completion
            callerQueue.addOperation { block(result) }
        }
    }
}

class CalculatePointsOperation: CalculateOperation<CalculatePointsResult, Date> {
    override func calculateResult() -> CalculatePointsResult {
        abort()
    }
}

class CalculateFocusOperation: CalculateOperation<CalculateFocusResult, [ChartRange]> {
    override func calculateResult() -> CalculateFocusResult {
        abort()
    }
}
