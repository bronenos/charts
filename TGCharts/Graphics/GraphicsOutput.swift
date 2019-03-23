//
//  GraphicsOutput.swift
//  TGCharts
//
//  Created by Stan Potemkin on 23/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation

final class GraphicsOutputRef {
    let outputUUID: UUID
    weak var graphics: IGraphics?
    
    init(outputUUID: UUID, graphics: IGraphics) {
        self.outputUUID = outputUUID
        self.graphics = graphics
    }
    
    deinit {
    }
}
