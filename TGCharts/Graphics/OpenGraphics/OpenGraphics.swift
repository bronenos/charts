//
//  OpenGraphics.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

final class OpenGraphics: IGraphics {
    private let renderView = OpenGraphicsRenderView()
    
    private let context: EAGLContext
    private var renderSize = CGSize.zero
    private var renderScale = CGFloat(0)
    private var frameBuffer = GLuint(0)
    private var renderBuffer = GLuint(0)
    private var renderTexture = GLuint(0)
    
    init(context: EAGLContext) {
        self.context = context
    }
    
    deinit {
        closeEnvironment()
    }
    
    var engineName: String {
        return "OpenGL"
    }
    
    func link(to view: UIView) {
        guard !renderView.isDescendant(of: view) else { return }
        view.addSubview(renderView)
        
        renderView.frame = view.bounds
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupEnvironment()
    }
    
    func unlink(from view: UIView) {
        guard renderView.isDescendant(of: view) else { return }
        renderView.removeFromSuperview()
        closeEnvironment()
    }
    
    func render(drawingBlock: (IGraphics) -> Void) {
        EAGLContext.setCurrent(context)
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_RENDERBUFFER.to_enum, renderBuffer)
        glViewport(0, 0, renderSize.width.to_size, renderSize.height.to_size)
        
        glMatrixMode(GL_PROJECTION.to_enum)
        glLoadIdentity()
        glOrthof(0, renderSize.width.to_float, 0, renderSize.height.to_float, -1, 1)
        
        glMatrixMode(GL_MODELVIEW.to_enum)
        glLoadIdentity()
        
        drawingBlock(self)
        
        glFramebufferTexture2D(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_TEXTURE_2D.to_enum, renderTexture, 0)
        
        context.presentRenderbuffer(GL_RENDERBUFFER.to_int)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_RENDERBUFFER.to_enum, 0)
        
        EAGLContext.setCurrent(nil)
    }
    
    func setBackground(color: UIColor) {
        var r = CGFloat(0), g = CGFloat(0), b = CGFloat(0), a = CGFloat(0)
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        glClearColor(r.to_clamp, g.to_clamp, b.to_clamp, a.to_clamp)
        glClear(GL_COLOR_BUFFER_BIT.to_bitfield)
    }
    
    func drawLine(points: [CGPoint], color: UIColor, width: CGFloat) {
        var r = CGFloat(0), g = CGFloat(0), b = CGFloat(0), a = CGFloat(0)
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        glColor4f(r.to_float, g.to_float, b.to_float, a.to_float)
        glLineWidth(width.to_float);
        
        glEnableClientState(GL_VERTEX_ARRAY.to_enum);
        
        var coords = [GLfloat](repeating: 0, count: points.count * 2)
        points.enumerated().forEach { index, point in
            coords[index * 2 + 0] = point.x.to_float
            coords[index * 2 + 1] = point.y.to_float
        }
        
        glVertexPointer(2, GL_FLOAT.to_enum, 0, coords)
        glDrawArrays(GL_LINE_STRIP.to_enum, 0, points.count.to_size)
        
        glDisableClientState(GL_VERTEX_ARRAY.to_enum);
    }
    
    private func setupEnvironment() {
        guard renderBuffer == 0 else { return }
        
        renderSize = renderView.bounds.size
        renderScale = UIScreen.main.scale
        
        renderSize.width *= renderScale
        renderSize.height *= renderScale
        
        EAGLContext.setCurrent(context)
        
        glGenRenderbuffers(1, &renderBuffer)
        if renderBuffer > 0 {
            glBindRenderbuffer(GL_RENDERBUFFER.to_enum, renderBuffer)
            context.renderbufferStorage(GL_RENDERBUFFER.to_int, from: renderView.drawableLayer)
        }
        
        glGenFramebuffers(1, &frameBuffer)
        if frameBuffer > 0 {
            glBindFramebuffer(GL_FRAMEBUFFER.to_enum, frameBuffer)
        }
        
        glGenTextures(1, &renderTexture)
        if renderTexture > 0 {
            glBindTexture(GL_TEXTURE_2D.to_enum, renderTexture)
            glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_MAG_FILTER.to_enum, GL_LINEAR.to_float)
            glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_MIN_FILTER.to_enum, GL_LINEAR.to_float)
            glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_WRAP_S.to_enum, GL_CLAMP_TO_EDGE.to_float)
            glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_WRAP_T.to_enum, GL_CLAMP_TO_EDGE.to_float)
            glTexImage2D(GL_TEXTURE_2D.to_enum, 0, GL_RGBA, renderSize.width.to_size, renderSize.height.to_size, 0, GL_RGBA.to_enum, GL_UNSIGNED_BYTE.to_enum, nil)
        }
        
        glBlendFunc(GL_SRC_ALPHA.to_enum, GL_ONE_MINUS_SRC_ALPHA.to_enum)
        
        EAGLContext.setCurrent(nil)
    }
    
    private func closeEnvironment() {
        EAGLContext.setCurrent(context)
        
        glBindFramebuffer(GL_FRAMEBUFFER.to_enum, 0)
        glDeleteFramebuffers(1, &frameBuffer)
        frameBuffer = 0
        
        glBindRenderbuffer(GL_RENDERBUFFER.to_enum, 0)
        glDeleteRenderbuffers(1, &renderBuffer)
        renderBuffer = 0
        
        glBindTexture(GL_TEXTURE_2D.to_enum, 0)
        glDeleteTextures(1, &renderTexture)
        renderTexture = 0
        
        EAGLContext.setCurrent(nil)
    }
}

fileprivate extension Int {
    var to_size: GLsizei {
        return GLsizei(self)
    }
}

fileprivate extension Int32 {
    var to_int: Int {
        return Int(self)
    }
    
    var to_float: GLfloat {
        return GLfloat(self)
    }
    
    var to_enum: GLenum {
        return GLenum(self)
    }
    
    var to_bitfield: GLbitfield {
        return GLbitfield(self)
    }
}

fileprivate extension CGFloat {
    var to_float: GLfloat {
        return GLfloat(self)
    }
    
    var to_size: GLsizei {
        return GLsizei(self)
    }
    
    var to_clamp: GLclampf {
        return GLclampf(self)
    }
}
