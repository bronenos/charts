//
//  UIViewExtensions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 14/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func layout(duration: TimeInterval) {
        setNeedsLayout()
        
        if duration > 0 {
            UIView.animate(withDuration: duration, animations: layoutIfNeeded)
        }
        else {
            layoutIfNeeded()
        }
    }
}
