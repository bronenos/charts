//
//  OpenGraphicsRenderView.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit
import OpenGLES

final class OpenGraphicsRenderView: UIView {
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    var drawableLayer: EAGLDrawable {
        return layer as! EAGLDrawable
    }
}
