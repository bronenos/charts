//
//  ChartGraphNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 12/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGraphNode: IChartSlicableNode {
    var container: IChartGraphContainer? { get set }
}

class ChartGraphNode: ChartNode, IChartGraphNode {
    weak var container: IChartGraphContainer?
    
    let chart: Chart
    private(set) var config: ChartConfig
    
    let graphContainer = ChartView()

    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        self.chart = chart
        self.config = config
        
        super.init(frame: .zero)
        
        graphContainer.clipsToBounds = true
        graphContainer.tag = ChartControlTag.graph.rawValue
        addSubview(graphContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(config: ChartConfig, duration: TimeInterval) {
        self.config = config
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
    }
}
