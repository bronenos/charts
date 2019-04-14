//
//  CGFloatExtensions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

extension CGFloat {
    func percent(from: CGFloat, to: CGFloat) -> CGFloat {
        let base = to - from
        guard base != 0 else { return 0 }
        
        let value = (self - from) / base
        return value
    }
    
    func percent(inside range: ChartRange) -> CGFloat {
        let base = range.end - range.start
        guard base != 0 else { return 0 }
        
        let value = (self - range.start) / base
        return value
    }
    
    func triangulate(from: CGFloat, to: CGFloat) -> CGFloat {
        return from + (to - from) * self
    }
}
