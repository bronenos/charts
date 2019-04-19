//
//  CGVectorExtensions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

extension CGVector {
    init(_ point: CGPoint) {
        self.init(dx: point.x, dy: point.y)
    }
    
    @discardableResult static func +=(fst: inout CGVector, snd: CGVector) -> CGVector {
        fst.dx += snd.dx
        fst.dy += snd.dy
        return fst
    }
}
