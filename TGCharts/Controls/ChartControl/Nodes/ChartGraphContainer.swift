//
//  ChartGraphContainer.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGraphContainer: IChartNode {
    func inject(graph: ChartGraphNode)
    func adjustGuides(left: ChartRange?, right: ChartRange?, duration: TimeInterval)
    func adjustPointer(chart: Chart, config: ChartConfig, meta: ChartSliceMeta, edges: [ChartRange], options: ChartPointerOptions)
}

final class ChartGraphContainer: ChartNode, IChartGraphContainer {
    let guidesContainer: ChartGuideContainer
    let pointerContainer: ChartPointerNode

    private var innerGraph: ChartGraphNode?
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        guidesContainer = ChartGuideContainer(chart: chart, config: config, formattingProvider: formattingProvider)
        pointerContainer = ChartPointerNode(chart: chart, formattingProvider: formattingProvider)

        super.init(frame: .zero)
        
        guidesContainer.isUserInteractionEnabled = false
        addSubview(guidesContainer)
        
        pointerContainer.isUserInteractionEnabled = false
        addSubview(pointerContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func inject(graph: ChartGraphNode) {
        guard graph !== innerGraph else { return }
        
        innerGraph?.container = nil
        innerGraph?.removeFromSuperview()
        
        innerGraph = graph
        innerGraph?.container = self
        insertSubview(graph, belowSubview: guidesContainer)
    }
    
    func adjustGuides(left: ChartRange?, right: ChartRange?, duration: TimeInterval) {
        guidesContainer.update(leftEdge: left, rightEdge: right, duration: duration)
    }
    
    func adjustPointer(chart: Chart, config: ChartConfig, meta: ChartSliceMeta, edges: [ChartRange], options: ChartPointerOptions) {
        pointerContainer.update(chart: chart, config: config, meta: meta, edges: edges, options: options)
    }
    
    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.primaryBackground)
        innerGraph?.updateDesign()
        guidesContainer.updateDesign()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return innerGraph?.sizeThatFits(.zero) ?? .zero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        innerGraph?.frame = bounds
        guidesContainer.frame = bounds
        pointerContainer.frame = bounds
    }
}
