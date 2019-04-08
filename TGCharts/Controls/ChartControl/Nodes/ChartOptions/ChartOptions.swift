//
//  ChartOptions.swift
//  TGCharts
//
//  Created by Stan Potemkin on 07/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartOptions: class {
    var tokenTapHandler: ((Int) -> Void)? { get set }
    func populate(_ options: [ChartOption])
}

final class ChartOptions: ChartNode, IChartOptions {
    var tokenTapHandler: ((Int) -> Void)?
    
    private var tokenOptions = [ChartOption]()
    private var tokenControls = [ChartOptionToken]()
    
    func populate(_ options: [ChartOption]) {
        self.tokenOptions = options
        
        if options.count == tokenControls.count {
            zip(options, tokenControls).forEach { option, control in
                control.configure(color: option.color, title: option.title, enabled: option.enabled)
            }
        }
        else {
            tokenControls.forEach { $0.removeFromSuperview() }
            
            tokenControls = options.map { option in
                let control = ChartOptionToken()
                control.configure(color: option.color, title: option.title, enabled: option.enabled)
                control.addTarget(self, action: #selector(handleTokenTap), for: .touchUpInside)
                return control
            }
            
            tokenControls.forEach { addSubview($0) }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        zip(tokenControls, layout.tokenControlsFrames).forEach { $0.0.frame = $0.1 }
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            tokenControls: tokenControls
        )
    }
    
    @objc private func handleTokenTap(_ control: ChartOptionToken) {
        guard let index = tokenControls.firstIndex(of: control) else { return }
        tokenTapHandler?(index)
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let tokenControls: [ChartOptionToken]
    
    private let verticalGap = CGFloat(10)
    private let horizontalGap = CGFloat(0)
    private let innerGap = CGFloat(5)
    private let tokenHeight = CGFloat(30)

    var tokenControlsFrames: [CGRect] {
        var rect = CGRect(x: horizontalGap, y: verticalGap, width: 0, height: tokenHeight)
        return tokenControls.map { control in
            let size = control.sizeThatFits(.zero)
            rect.size.width = size.width
            
            defer {
                rect.origin.x = rect.maxX + innerGap
            }
            
            if rect.maxX > bounds.width - horizontalGap {
                rect.origin.y = rect.maxY + innerGap
                rect.origin.x = horizontalGap
            }
            
            return rect
        }
    }
    
    var totalSize: CGSize {
        let height = tokenControlsFrames.last?.maxY ?? 0
        return CGSize(width: bounds.width, height: height + verticalGap)
    }
}
