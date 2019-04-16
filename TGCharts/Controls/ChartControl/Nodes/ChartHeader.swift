//
//  ChartHeader.swift
//  TGCharts
//
//  Created by Stan Potemkin on 07/04/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

protocol IChartHeader: IChartNode {
    var zoomOutHandler: (() -> Void)? { get set }
    func setZoomable(_ value: Bool)
    func setSingleDate(_ date: Date)
    func setDateInterval(sinceDate: Date, untilDate: Date)
}

final class ChartHeader: ChartNode, IChartHeader {
    var zoomOutHandler: (() -> Void)?
    
    private let formattingProvider: IFormattingProvider
    
    private let zoomOutButton = UIButton()
    private let dateHeader = UILabel()
    
    init(zoomOutTitle: String, formattingProvider: IFormattingProvider) {
        self.formattingProvider = formattingProvider
        
        super.init(frame: .zero)
        
        zoomOutButton.titleLabel?.font = DesignBook.shared.font(size: 12, weight: .regular)
        zoomOutButton.setTitle(zoomOutTitle, for: .normal)
        zoomOutButton.addTarget(self, action: #selector(handleZoomOut), for: .touchUpInside)
        zoomOutButton.isHidden = true
        addSubview(zoomOutButton)
        
        dateHeader.font = DesignBook.shared.font(size: 13, weight: .medium)
        addSubview(dateHeader)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setZoomable(_ value: Bool) {
        zoomOutButton.isHidden = !value
        
        setNeedsLayout()
    }
    
    func setSingleDate(_ date: Date) {
        let text = formattingProvider.format(date: date, style: .fullDate)
        dateHeader.text = text
        
        setNeedsLayout()
    }
    
    func setDateInterval(sinceDate: Date, untilDate: Date) {
        let sinceText = formattingProvider.format(date: sinceDate, style: .mediumDate)
        let untilText = formattingProvider.format(date: untilDate, style: .mediumDate)
        dateHeader.text = "\(sinceText) - \(untilText)"
        
        setNeedsLayout()
    }
    
    override func updateDesign() {
        super.updateDesign()
        zoomOutButton.setTitleColor(DesignBook.shared.color(.actionForeground), for: .normal)
        dateHeader.textColor = DesignBook.shared.color(.primaryForeground)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layout = getLayout(size: bounds.size)
        zoomOutButton.frame = layout.zoomOutButtonFrame
        dateHeader.frame = layout.dateHeaderFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            zoomOutButton: zoomOutButton,
            dateHeader: dateHeader
        )
    }
    
    @objc private func handleZoomOut() {
        zoomOutHandler?()
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let zoomOutButton: UIButton
    let dateHeader: UILabel
    
    private let gap = CGFloat(10)
    private let height = CGFloat(45)

    var zoomOutButtonFrame: CGRect {
        let size = zoomOutButton.sizeThatFits(.zero)
        let topY = (bounds.height - size.height) * 0.5
        return CGRect(x: gap, y: topY, width: size.width, height: size.height)
    }
    
    var dateHeaderFrame: CGRect {
        let size = dateHeader.sizeThatFits(.zero)
        let leftX = max((bounds.width - size.width) * 0.5, zoomOutButtonFrame.maxX + gap)
        let topY = (bounds.height - size.height) * 0.5
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }
    
    var totalSize: CGSize {
        return CGSize(width: bounds.width, height: height)
    }
}
