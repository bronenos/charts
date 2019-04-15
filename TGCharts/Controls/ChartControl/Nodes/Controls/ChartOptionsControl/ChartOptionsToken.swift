//
//  ChartOptionsToken.swift
//  TGCharts
//
//  Created by Stan Potemkin on 07/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

final class ChartOptionsToken: UIView {
    var tapHandler: (() -> Void)?
    
    private let titleLabel = UILabel()
    private let enabledLabel = UILabel()
    private let button = UIButton()
    
    private var isEnabled = true
    
    init() {
        super.init(frame: .zero)
        
        titleLabel.font = DesignBook.shared.font(size: 13, weight: .regular)
        addSubview(titleLabel)
        
        enabledLabel.text = String("✓")
        enabledLabel.textColor = DesignBook.shared.color(.optionForeground)
        enabledLabel.font = DesignBook.shared.font(size: 15, weight: .medium)
        enabledLabel.sizeToFit()
        addSubview(enabledLabel)
        
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addSubview(button)
        
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func configure(color: UIColor, title: String, enabled: Bool, animated: Bool) {
        isEnabled = enabled
        
        titleLabel.text = title
        layer.borderWidth = 1
        layer.borderColor = color.cgColor

        func _block() {
            if isEnabled {
                titleLabel.textColor = DesignBook.shared.color(.optionForeground)
                backgroundColor = color
            }
            else {
                titleLabel.textColor = color
                backgroundColor = UIColor.clear
            }
        }
        
        
        if animated {
            setNeedsLayout()
            UIView.animate(
                withDuration: DesignBook.shared.duration(.toggleOption),
                animations: { [weak self] in
                    _block()
                    self?.layoutIfNeeded()
                }
            )
        }
        else {
            _block()
            setNeedsLayout()
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: bounds.size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        titleLabel.frame = layout.titleLabelFrame
        enabledLabel.frame = layout.enabledLabelFrame
        button.frame = layout.buttonFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: bounds,
            titleLabel: titleLabel,
            enabledLabel: enabledLabel,
            isEnabled: isEnabled
        )
    }
    
    @objc private func handleTap() {
        tapHandler?()
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let titleLabel: UILabel
    let enabledLabel: UILabel
    let isEnabled: Bool
    
    private let gaps = UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
    private let innerGap = CGFloat(7)

    var titleLabelFrame: CGRect {
        let size = titleLabel.sizeThatFits(.zero)
        let topY = (bounds.height - size.height) * 0.5
        
        if isEnabled {
            let leftX = enabledLabelFrame.maxX + innerGap
            return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        }
        else {
            let leftX = (bounds.width - size.width) * 0.5
            return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        }
    }
    
    var enabledLabelFrame: CGRect {
        let size = enabledLabel.sizeThatFits(.zero)
        let topY = (bounds.height - size.height) * 0.5
        
        if isEnabled {
            let leftX = gaps.left
            return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        }
        else {
            let leftX = -size.width
            return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
        }
    }
    
    var buttonFrame: CGRect {
        return bounds
    }
    
    var totalSize: CGSize {
        let titleSize = titleLabel.sizeThatFits(.zero)
        let enabledSize = enabledLabel.sizeThatFits(.zero)
        
        let width = gaps.left + enabledSize.width + innerGap + titleSize.width + gaps.right
        let height = gaps.top + max(titleSize.height, enabledSize.height) + gaps.bottom
        return CGSize(width: width, height: height)
    }
}
