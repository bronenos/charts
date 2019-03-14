//
//  CGPointExtensions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    init(_ vector: CGVector) {
        self.init(x: vector.dx, y: vector.dy)
    }
    
    static func -(fst: CGPoint, snd: CGPoint) -> CGVector {
        return CGVector(dx: fst.x - snd.x, dy: fst.y - snd.y)
    }
}
