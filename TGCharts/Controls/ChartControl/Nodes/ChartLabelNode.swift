//
//  ChartLabelNode.swift
//  TGCharts
//
//  Created by Stan Potemkin on 16/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct ChartLabelNodeContent {
    let text: String
    let color: UIColor
    let font: UIFont
    let alignment: NSTextAlignment
    let limitedToBounds: Bool
}

protocol IChartLabelNode: IChartNode {
    var content: ChartLabelNodeContent? { get set }
    func calculateSize() -> CGSize
}

final class ChartLabelNode: ChartNode, IChartLabelNode {
    var content: ChartLabelNodeContent?
    
    private var textureRef: GraphicsTextureRef?
    
    override func render(graphics: IGraphics) -> Bool {
        guard super.render(graphics: graphics) else { return false }
        
        if let ref = textureRef {
            graphics.drawTexture(ref, in: bounds)
        }
        else if let meta = generateTextureMeta(), let ref = graphics.storeTexture(meta: meta) {
            graphics.drawTexture(ref, in: bounds)
            textureRef = ref
        }
        
        return true
    }
    
    func calculateSize() -> CGSize {
        guard let content = content else { return .zero }
        guard let string = constructAttributedString() else { return .zero }
        
        let drawingBounds = string.boundingRect(
            with: CGSize(
                width: content.limitedToBounds ? size.width : .infinity,
                height: .infinity
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return drawingBounds.size
    }
    
    private func constructAttributedString() -> NSAttributedString? {
        guard let content = content else { return nil }
        
        let style = NSMutableParagraphStyle()
        style.alignment = content.alignment
        
        return NSMutableAttributedString(
            string: content.text,
            attributes: [
                NSAttributedString.Key.foregroundColor: content.color,
                NSAttributedString.Key.font: content.font,
                NSAttributedString.Key.paragraphStyle: style
            ]
        )
    }
    
    private func generateTextureMeta() -> GraphicsTextureMeta? {
        guard let content = content else { return nil }
        guard let string = constructAttributedString() else { return nil }
        
        let drawingBounds = CGRect(origin: .zero, size: calculateSize())
        let image = UIGraphicsImageRenderer(bounds: drawingBounds).image { context in
            string.draw(in: drawingBounds)
        }
        
//        if let path = ProcessInfo.processInfo.environment["TEXTURE_OUT_PRINT"] {
//            let url = URL(fileURLWithPath: path)
//            try? image.pngData()?.write(to: url)
//        }
        
        return image.cgImage.flatMap { ref in
            let width = calculateCoveringDuoPower(value: ref.width)
            let height = calculateCoveringDuoPower(value: ref.height)
            let bytesPerPixel = MemoryLayout<UInt32>.size
            let bitsPerComponent = 8

            let pixelSize = CGSize(width: CGFloat(ref.width), height: CGFloat(ref.height))
            let textureSize = CGSize(width: CGFloat(width), height: CGFloat(height))
            
            var rawBytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
            let context = CGContext(
                data: &rawBytes,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: width * bytesPerPixel,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            
            context?.draw(
                ref,
                in: CGRect(origin: .zero, size: pixelSize)
            )
            
            return GraphicsTextureMeta(
                bytes: rawBytes,
                pointSize: drawingBounds.size,
                pixelSize: pixelSize,
                textureSize: textureSize,
                alignment: content.alignment
            )
        }
    }
    
    private func calculateCoveringDuoPower(value: Int) -> Int {
        for i in (0 ..< 32).indices.reversed() {
            let bit = ((value & (1 << i)) > 0)
            guard bit else { continue }
            
            if value.nonzeroBitCount > 1 {
                return (1 << (i + 1))
            }
            else {
                return (1 << i)
            }
        }
        
        return 1
    }
}
