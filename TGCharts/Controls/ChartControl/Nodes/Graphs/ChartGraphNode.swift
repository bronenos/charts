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

class ChartGraphNode: ChartNode, IChartGraphNode {
    weak var container: IChartGraphContainer?
    
    let chart: Chart
    private(set) var config: ChartConfig

    let graphContainer = ChartView()
    var lineNodes = [String: ChartFigureNode]()

    private var lastMeta: ChartSliceMeta?
    let calculationQueue = OperationQueue()
    var cachedResult: CalculateOperation.Result?
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = config
        
        super.init(frame: .zero)
        
        clipsToBounds = true
        
        calculationQueue.maxConcurrentOperationCount = 1
        calculationQueue.qualityOfService = .userInteractive
        
        graphContainer.tag = ChartControlTag.graph.rawValue
        addSubview(graphContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final func configure(figure: ChartFigure, block: @escaping (Int, ChartFigureNode, ChartLine) -> Void) {
        chart.lines.enumerated().forEach { index, line in
            let node = ChartFigureNode(figure: figure)
            block(index, node, line)
            
            lineNodes[line.key] = node
            graphContainer.addSubview(node)
        }
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
        
        if duration > 0 {
            lineNodes.values.forEach { $0.overwriteNextAnimation(duration: duration) }
        }
        
        enqueueRecalculation(duration: duration)
    }
    
    func obtainCalculationOperation(meta: ChartSliceMeta, duration: TimeInterval) -> CalculateOperation {
        abort()
    }
    
    func adjustPointer(meta: ChartSliceMeta) {
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
        graphContainer.frame = bounds
        enqueueRecalculation(duration: 0)
    }
    
    private func enqueueRecalculation(duration: TimeInterval) {
        let meta = chart.obtainMeta(
            config: config,
            bounds: bounds
        )
        
        if meta != lastMeta {
            lastMeta = meta
            enqueueCalculation(
                operation: obtainCalculationOperation(
                    meta: meta,
                    duration: duration
                ),
                duration: duration
            )
        }
        else {
            adjustPointer(meta: meta)
        }
    }
    
    private func enqueueCalculation(operation: Operation, duration: TimeInterval) {
        if let _ = cachedResult {
            if calculationQueue.operations.isEmpty {
                calculationQueue.addOperation(operation)
            }
        }
        else {
            operation.main()
        }
    }
}

class CalculateOperation: Operation {
    struct Result {
        let range: ChartRange
        let edges: [ChartRange]
        let points: [String: [CGPoint]]
    }
    
    let chart: Chart
    let config: ChartConfig
    let meta: ChartSliceMeta
    let bounds: CGRect
    let completion: ((Result) -> Void)
    
    private let callerQueue = OperationQueue.current ?? .main
    
    init(chart: Chart,
         config: ChartConfig,
         meta: ChartSliceMeta,
         bounds: CGRect,
         completion: @escaping ((Result) -> Void)) {
        self.chart = chart
        self.config = config
        self.meta = meta
        self.bounds = bounds
        self.completion = completion
    }
    
    func calculateResult() -> Result {
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
