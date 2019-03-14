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
    weak var delegate: IGraphicsDelegate?
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isExclusiveTouch = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        abort()
    }
    
    var drawableLayer: EAGLDrawable {
        return layer as! EAGLDrawable
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            delegate?.interactionDidStart(at: point)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            delegate?.interactionDidMove(to: point)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            delegate?.interactionDidEnd(at: point)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        if let point = touches.first?.location(in: self) {
            delegate?.interactionDidEnd(at: point)
        }
    }
}
