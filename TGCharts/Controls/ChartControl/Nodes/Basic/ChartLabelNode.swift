//
//  ChartLabelNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 16/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartLabelNodeContent: Equatable {
    let text: String
    let color: UIColor
    let font: UIFont
    let alignment: NSTextAlignment
    let limitedToBounds: Bool
    
    static func ==(lhs: ChartLabelNodeContent, rhs: ChartLabelNodeContent) -> Bool {
        guard lhs.text == rhs.text else { return false }
        guard lhs.color == rhs.color else { return false }
        guard lhs.font == rhs.font else { return false }
        guard lhs.alignment == rhs.alignment else { return false }
        guard lhs.limitedToBounds == rhs.limitedToBounds else { return false }
        return true
    }
}

protocol IChartLabelNode: IChartNode {
}

final class ChartLabelNode: UILabel, IChartLabelNode {
    func updateDesign() {
    }
    
    func discardCache() {
    }
}
