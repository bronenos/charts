//
//  UIColorExtensions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    @objc(initWithHexCode:) convenience init(hex: Int) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat((hex & 0x0000FF) >> 0) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    @objc(initWithHexString:) convenience init(hex: String) {
        let source: String
        if hex.hasPrefix("#") {
            source = String(hex.dropFirst())
        }
        else {
            source = hex
        }
        
        if let code = Int(source, radix: 16) {
            self.init(hex: code)
        }
        else {
            self.init(white: 0, alpha: 1.0)
        }
    }
}
