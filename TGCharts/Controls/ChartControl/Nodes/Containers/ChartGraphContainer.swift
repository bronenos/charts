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
    func update(config: ChartConfig, shouldUpdateEye: Bool, duration: TimeInterval)
    
    func adjustDates(sinceDate: Date,
                     lastDate: Date,
                     duration: TimeInterval)
    
    func adjustGuides(leftOptions: ChartGuideOptions?,
                      rightOptions: ChartGuideOptions?,
                      duration: TimeInterval)
    
    func adjustPointer(pointing: ChartGraphPointing?,
                       content: ChartPointerCloudContent?,
                       options: ChartPointerOptions,
                       duration: TimeInterval)
}

final class ChartGraphContainer: ChartNode, IChartGraphContainer {
    private let headerNode: ChartHeader?
    private var mainGraphHeight: CGFloat
    
    private let guidesContainer: ChartGuideContainer
    private let pointerContainer: ChartPointerContainer
    private var innerGraph: ChartGraphNode?
    
    init(chart: Chart, config: ChartConfig, headerNode: ChartHeader?, formattingProvider: IFormattingProvider, mainGraphHeight: CGFloat, enableControls: Bool) {
        self.headerNode = headerNode
        self.mainGraphHeight = mainGraphHeight
        
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
    
    func updateHeight(mainGraphHeight: CGFloat) {
        self.mainGraphHeight = mainGraphHeight
    }
    
    func update(config: ChartConfig, shouldUpdateEye: Bool, duration: TimeInterval) {
        innerGraph?.update(config: config, shouldUpdateEye: shouldUpdateEye, duration: duration)
    }
    
    func adjustDates(sinceDate: Date, lastDate: Date, duration: TimeInterval) {
        headerNode?.setDateInterval(sinceDate: sinceDate, untilDate: lastDate)
    }
    
    func adjustGuides(leftOptions: ChartGuideOptions?, rightOptions: ChartGuideOptions?, duration: TimeInterval) {
        guidesContainer.update(leftOptions: leftOptions, rightOptions: rightOptions, duration: duration)
    }
    
    func adjustPointer(pointing: ChartGraphPointing?,
                       content: ChartPointerCloudContent?,
                       options: ChartPointerOptions,
                       duration: TimeInterval) {
        pointerContainer.update(
            pointing: pointing,
            content: content,
            options: options,
            duration: duration
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
        return CGSize(width: size.width, height: mainGraphHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        innerGraph?.frame = bounds
        guidesContainer.frame = bounds
        pointerContainer.frame = bounds
    }
}
