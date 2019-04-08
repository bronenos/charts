//
//  ChartOptionToken.swift
//  TGCharts
//
//  Created by Stan Potemkin on 07/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

final class ChartOptionToken: UIButton {
    init() {
        super.init(frame: .zero)
        
        titleLabel?.font = DesignBook.shared.font(size: 13, weight: .regular)
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func configure(color: UIColor, title: String, enabled: Bool) {
        setTitle(title, for: .normal)
        
        if enabled {
            backgroundColor = color
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
            setTitleColor(UIColor.white, for: .normal)
        }
        else {
            backgroundColor = UIColor.clear
            layer.borderWidth = 1
            layer.borderColor = color.cgColor
            setTitleColor(color, for: .normal)
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let originalSize = super.sizeThatFits(size)
        return CGSize(width: originalSize.width + 40, height: originalSize.height)
    }
}
