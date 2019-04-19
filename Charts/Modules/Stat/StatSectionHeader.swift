//
//  StatSectionHeader.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

final class StatSectionHeader: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(
            in: rect
                .divided(atDistance: 15, from: .minXEdge).remainder
                .divided(atDistance: 5, from: .maxYEdge).remainder
        )
    }
}
