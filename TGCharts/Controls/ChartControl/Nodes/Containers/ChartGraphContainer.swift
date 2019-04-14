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
    func update(config: ChartConfig, duration: TimeInterval)
    func adjustGuides(left: ChartRange?, right: ChartRange?, duration: TimeInterval)
    func adjustPointer(chart: Chart, config: ChartConfig, eyes: [ChartGraphEye], options: ChartPointerOptions, duration: TimeInterval)
}

final class ChartGraphContainer: ChartNode, IChartGraphContainer {
    let guidesContainer: ChartGuideContainer
    let pointerContainer: ChartPointerContainer

    private var innerGraph: ChartGraphNode?
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider, enableControls: Bool) {
        guidesContainer = ChartGuideContainer(chart: chart, config: config, formattingProvider: formattingProvider)
        pointerContainer = ChartPointerContainer(chart: chart, formattingProvider: formattingProvider)

        super.init(frame: .zero)
        
        guidesContainer.isUserInteractionEnabled = false
        guidesContainer.isHidden = !enableControls
        addSubview(guidesContainer)
        
        pointerContainer.isUserInteractionEnabled = false
        pointerContainer.isHidden = !enableControls
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
    
    func update(config: ChartConfig, duration: TimeInterval) {
        innerGraph?.update(config: config, duration: duration)
    }
    
    func adjustGuides(left: ChartRange?, right: ChartRange?, duration: TimeInterval) {
        guidesContainer.update(leftEdge: left, rightEdge: right, duration: duration)
    }
    
    func adjustPointer(chart: Chart, config: ChartConfig, eyes: [ChartGraphEye], options: ChartPointerOptions, duration: TimeInterval) {
        pointerContainer.update(
            chart: chart,
            config: config,
            pointing: config.pointer.flatMap { pointer in
                innerGraph?.calculatePointing(pointer: pointer)
            },
            options: options,
            duration: duration * 2
        )
    }
    
    override func discardCache() {
        super.discardCache()
        innerGraph?.discardCache()
    }

    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.primaryBackground)
        innerGraph?.updateDesign()
        guidesContainer.updateDesign()
        pointerContainer.updateDesign()
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
