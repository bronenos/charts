//
//  ChartOperation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartEyeOperationContext {
    let valueEdges: [ChartRange]
    let totalEdges: [ChartRange]
    let lineEdges: [ChartRange]
}

class ChartOperation<Type, Context>: Operation {
    let chart: Chart
    let config: ChartConfig
    let meta: ChartSliceMeta
    let bounds: CGRect
    let context: Context
    let completion: ((Type) -> Void)
    
    private let callerQueue = OperationQueue.current ?? .main
    
    init(chart: Chart,
         config: ChartConfig,
         meta: ChartSliceMeta,
         bounds: CGRect,
         context: Context,
         completion: @escaping ((Type) -> Void)) {
        self.chart = chart
        self.config = config
        self.meta = meta
        self.bounds = bounds
        self.context = context
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

class ChartPointsOperation: ChartOperation<CalculatePointsResult, Int> {
    override func calculateResult() -> CalculatePointsResult {
        abort()
    }
}

class ChartEyesOperation: ChartOperation<CalculateEyesResult, ChartEyeOperationContext> {
    override func calculateResult() -> CalculateEyesResult {
        abort()
    }
}
