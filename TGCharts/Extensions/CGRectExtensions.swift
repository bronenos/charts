//
//  CGRectExtensions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 13/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    var bottomLeftPoint: CGPoint {
        return CGPoint(x: minX, y: maxY)
    }
    
    var bottomRightPoint: CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
    
    var topLeftPoint: CGPoint {
        return CGPoint(x: minX, y: minY)
    }
    
    var topRightPoint: CGPoint {
        return CGPoint(x: maxX, y: minY)
    }
}
