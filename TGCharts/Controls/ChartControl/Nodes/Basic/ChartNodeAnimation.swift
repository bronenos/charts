//
//  ChartNodeAnimation.swift
//  TGCharts
//
//  Created by Stan Potemkin on 23/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartNodeAnimation: class {
    var endTime: Date { get }
    var progress: CGFloat { get }
    var isFinished: Bool { get }
    func perform() -> Bool
}

class ChartNodeAnimation: IChartNodeAnimation {
    private let startTime: Date
    let endTime: Date
    
    private(set) weak var node: IChartNode?
    private(set) var isFinished = false
    
    init(duration: TimeInterval) {
        startTime = Date()
        endTime = Date(timeIntervalSinceNow: duration)
    }
    
    func attach(to node: IChartNode) {
        self.node = node
        node.addAnimation(self)
        _ = perform()
        node.prepareForAnimation(self)
    }
    
    final var progress: CGFloat {
        guard !isFinished else { return 1.0 }
        let spentTime = Date().timeIntervalSince(startTime)
        let totalTime = endTime.timeIntervalSince(startTime)
        return min(1.0, CGFloat(spentTime / totalTime))
    }

    func perform() -> Bool {
        if isFinished {
            return false
        }
        
        if progress == 1.0 {
            isFinished = true
        }
        
        node?.dirtify()
        
        return true
    }
}
