//
//  ChartOperation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

class ChartOperation<Type, Source>: Operation {
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

class ChartPointsOperation: ChartOperation<CalculatePointsResult, Date> {
    override func calculateResult() -> CalculatePointsResult {
        abort()
    }
}

class ChartFocusOperation: ChartOperation<CalculateFocusResult, [ChartRange]> {
    override func calculateResult() -> CalculateFocusResult {
        abort()
    }
}
