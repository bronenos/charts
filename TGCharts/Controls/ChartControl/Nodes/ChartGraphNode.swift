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
}

class ChartGraphNode: ChartNode, IChartGraphNode {
    let chart: Chart
    let guidable: Bool
    private(set) var config: ChartConfig
    
    let graphContainer = ChartView()
    let guidesContainer: ChartGuideNode
    let pointerContainer: ChartPointerNode

    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, guidable: Bool) {
        self.chart = chart
        self.guidable = guidable
        self.config = config
        
        guidesContainer = ChartGuideNode(chart: chart, config: config, formattingProvider: formattingProvider, enabled: guidable)
        pointerContainer = ChartPointerNode(chart: chart, formattingProvider: formattingProvider)
        
        super.init(frame: .zero)
        
        graphContainer.clipsToBounds = true
        graphContainer.tag = ChartControlTag.graph.rawValue
        addSubview(graphContainer)
        
        guidesContainer.clipsToBounds = true
        guidesContainer.isUserInteractionEnabled = false
        addSubview(guidesContainer)
        
        pointerContainer.isUserInteractionEnabled = false
        addSubview(pointerContainer)
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
        guidesContainer.updateDesign()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 300)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        graphContainer.frame = bounds
        guidesContainer.frame = bounds
        pointerContainer.frame = bounds
    }
}
