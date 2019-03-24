//
//  GraphicsTexture.swift
//  TGCharts
//
//  Created by Stan Potemkin on 17/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

struct GraphicsTextureMeta {
    let bytes: [UInt8]
    let pointSize: CGSize
    let pixelSize: CGSize
    let textureSize: CGSize
    let alignment: NSTextAlignment
}

final class GraphicsTextureRef {
    let textureUUID: UUID
    weak var graphics: IGraphics?
    
    init(textureUUID: UUID, graphics: IGraphics) {
        self.textureUUID = textureUUID
        self.graphics = graphics
    }
    
    var isValid: Bool {
        return (graphics?.isValidTexture(self) == true)
    }
    
    deinit {
        graphics?.discardTexture(self)
    }
}
