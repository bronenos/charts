//
//  ChartGuideContainer.swift
//  TGCharts
//
//  Created by Stan Potemkin on 08/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartGuideContainer: IChartNode {
    func update(leftOptions: ChartGuideOptions?, rightOptions: ChartGuideOptions?, duration: TimeInterval)
}

final class ChartGuideContainer: ChartNode, IChartGuideContainer {
    let leftGuidesNode: ChartGuideControl
    let rightGuidesNode: ChartGuideControl
    
    init(chart: Chart, config: ChartConfig, formattingProvider: IFormattingProvider) {
        leftGuidesNode = ChartGuideControl(
            chart: chart,
            config: config,
            alignment: .left,
            formattingProvider: formattingProvider
        )
        
        rightGuidesNode = ChartGuideControl(
            chart: chart,
            config: config,
            alignment: .right,
            formattingProvider: formattingProvider
        )
        
        super.init(frame: .zero)
        
        addSubview(leftGuidesNode)
        addSubview(rightGuidesNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func update(leftOptions: ChartGuideOptions?, rightOptions: ChartGuideOptions?, duration: TimeInterval) {
        leftGuidesNode.update(options: leftOptions, duration: duration)
        rightGuidesNode.update(options: rightOptions, duration: duration)
    }
    
    override func updateDesign() {
        super.updateDesign()
        leftGuidesNode.updateDesign()
        rightGuidesNode.updateDesign()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        leftGuidesNode.frame = bounds
        rightGuidesNode.frame = bounds
    }
}
