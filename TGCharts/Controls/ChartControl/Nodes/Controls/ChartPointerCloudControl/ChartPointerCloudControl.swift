//
//  ChartPointerCloudControl.swift
//  TGCharts
//
//  Created by Stan Potemkin on 19/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartPointerCloudContent {
    let header: String?
    let disclosable: Bool
    let values: [ChartPointerCloudValue]
}

struct ChartPointerCloudValue {
    let percent: String?
    let title: String
    let value: String
    let color: UIColor
}

protocol IChartPointerCloudControl: IChartNode {
    func populate(content: ChartPointerCloudContent)
}

final class ChartPointerCloudControl: ChartNode, IChartPointerCloudControl {
    let dateNode = ChartLabelNode()
    let arrowNode = ChartLabelNode()
    private let percentsNode = ChartLabelNode()
    private let titlesNode = ChartLabelNode()
    private let valuesNode = ChartLabelNode()
    
    init() {
        super.init(frame: .zero)
        
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
        dateNode.font = DesignBook.shared.font(size: 11, weight: .medium)
        dateNode.textAlignment = .left
        addSubview(dateNode)
        
        arrowNode.font = DesignBook.shared.font(size: 17, weight: .medium)
        arrowNode.textAlignment = .right
        addSubview(arrowNode)
        
        percentsNode.font = DesignBook.shared.font(size: 11, weight: .medium)
        percentsNode.textAlignment = .right
        percentsNode.numberOfLines = 0
        addSubview(percentsNode)
        
        titlesNode.font = DesignBook.shared.font(size: 11, weight: .light)
        titlesNode.textAlignment = .left
        titlesNode.numberOfLines = 0
        addSubview(titlesNode)
        
        valuesNode.font = DesignBook.shared.font(size: 11, weight: .medium)
        valuesNode.numberOfLines = 0
        addSubview(valuesNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    func populate(content: ChartPointerCloudContent) {
        func _style(alignment: NSTextAlignment) -> NSParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.alignment = alignment
            style.lineSpacing = 2
            return style
        }
        
        if let header = content.header {
            dateNode.attributedText = NSAttributedString(
                string: header,
                attributes: [
                    .foregroundColor: DesignBook.shared.color(.chartPointerCloudForeground),
                    .paragraphStyle: _style(alignment: .left)
                ]
            )
            
            arrowNode.attributedText = NSAttributedString(
                string: "›",
                attributes: [
                    .foregroundColor: DesignBook.shared.color(.chartPointerCloudForeground),
                    .paragraphStyle: _style(alignment: .right)
                ]
            )
        }
        else {
            dateNode.attributedText = nil
            
            arrowNode.attributedText = nil
        }
        
        if let _ = content.values.first?.percent {
            percentsNode.attributedText = NSAttributedString(
                string: content.values
                    .compactMap({ $0.percent })
                    .map({ "\($0)%" })
                    .joined(separator: "\n"),
                attributes: [
                    .paragraphStyle: _style(alignment: .right)
                ]
            )
        }
        else {
            percentsNode.attributedText = nil
        }
        
        if let font = titlesNode.font {
            let attributedText = NSMutableAttributedString()
            
            for (index, value) in content.values.enumerated() {
                attributedText.append(
                    NSAttributedString(
                        string: value.title,
                        attributes: [
                            .font: font,
                            .foregroundColor: DesignBook.shared.color(.chartPointerCloudForeground),
                            .paragraphStyle: _style(alignment: .left)
                        ]
                    )
                )
                
                attributedText.append(
                    NSAttributedString(
                        string: "0",
                        attributes: [
                            .font: font,
                            .foregroundColor: UIColor.clear,
                            .paragraphStyle: _style(alignment: .left)
                        ]
                    )
                )
                
                if index < content.values.endIndex - 1 {
                    attributedText.append(
                        NSAttributedString(
                            string: "\n",
                            attributes: [
                                .font: font,
                                .paragraphStyle: _style(alignment: .left)
                            ]
                        )
                    )
                }
            }
            
            titlesNode.attributedText = attributedText
        }
        else {
            titlesNode.attributedText = nil
        }
        
        if let font = valuesNode.font {
            let attributedText = NSMutableAttributedString()
            
            for (index, value) in content.values.enumerated() {
                attributedText.append(
                    NSAttributedString(
                        string: value.value,
                        attributes: [
                            .font: font,
                            .foregroundColor: value.color,
                            .paragraphStyle: _style(alignment: .right),
                        ]
                    )
                )

                if index < content.values.endIndex - 1 {
                    attributedText.append(
                        NSAttributedString(
                            string: "\n",
                            attributes: [
                                .font: font,
                                .foregroundColor: value.color,
                                .paragraphStyle: _style(alignment: .right)
                            ]
                        )
                    )
                }
            }
            
            valuesNode.attributedText = attributedText
        }
        
        layout(duration: 0)
    }
    
    override func updateDesign() {
        super.updateDesign()
        backgroundColor = DesignBook.shared.color(.chartPointerCloudBackground)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        dateNode.frame = layout.dateNodeFrame
        arrowNode.frame = layout.arrowNodeFrame
        percentsNode.frame = layout.percentsNodeFrame
        titlesNode.frame = layout.titlesNodeFrame
        valuesNode.frame = layout.valuesNodeFrame
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            dateNode: dateNode,
            arrowNode: arrowNode,
            percentsNode: percentsNode,
            titlesNode: titlesNode,
            valuesNode: valuesNode
        )
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let dateNode: ChartLabelNode
    let arrowNode: ChartLabelNode
    let percentsNode: ChartLabelNode
    let titlesNode: ChartLabelNode
    let valuesNode: ChartLabelNode

    private let horGap = CGFloat(9)
    private let verGap = CGFloat(7)
    private let dateInnerGap = CGFloat(5)
    private let percentsInnerGap = CGFloat(5)
    private let valuesInnerGap = CGFloat(15)

    var dateNodeFrame: CGRect {
        let size = dateNode.sizeThatFits(.zero)
        let topY = verGap
        return CGRect(x: horGap, y: topY, width: size.width, height: size.height)
    }
    
    var arrowNodeFrame: CGRect {
        let size = arrowNode.sizeThatFits(.zero)
        let topY = dateNodeFrame.midY - size.height * 0.5 - 1
        let leftX = bounds.width - horGap - size.width
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }
    
    var percentsNodeFrame: CGRect {
        let topY = dateNodeFrame.maxY + 2
        let leftX = horGap
        let size = (percentsNode.text == nil ? .zero : percentsNode.sizeThatFits(.zero))
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }

    var titlesNodeFrame: CGRect {
        let topY = dateNodeFrame.maxY + 2
        let leftX = (percentsNode.text == nil ? horGap : percentsNodeFrame.maxX + percentsInnerGap)
        let size = titlesNode.sizeThatFits(.zero)
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }
    
    var valuesNodeFrame: CGRect {
        let topY = dateNodeFrame.maxY + 2
        let size = valuesNode.sizeThatFits(.zero)
        let leftX = bounds.width - horGap - size.width
        return CGRect(x: leftX, y: topY, width: size.width, height: size.height)
    }
    
    var totalSize: CGSize {
        let widths = [
            (percentsNode.text == nil ? 0 : percentsNode.sizeThatFits(.zero).width + percentsInnerGap),
            titlesNode.sizeThatFits(.zero).width,
            valuesInnerGap,
            valuesNode.sizeThatFits(.zero).width,
        ]
        
        return CGSize(
            width: horGap * 2 + max(
                dateNode.sizeThatFits(.zero).width + dateInnerGap + arrowNode.sizeThatFits(.zero).width,
                widths.reduce(0, +)
            ),
            height: verGap + max(
                percentsNodeFrame.maxY,
                titlesNodeFrame.maxY,
                valuesNodeFrame.maxY
            )
        )
    }
}
