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
    
    private var backgroundColor = UIColor.white

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
    
    func setBackground(color: UIColor) {
        backgroundColor = color
    }
    
    func render() {
        EAGLContext.setCurrent(context)
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_RENDERBUFFER.to_enum, renderBuffer)
        glViewport(0, 0, renderSize.width.to_size, renderSize.height.to_size)
        
        glMatrixMode(GL_PROJECTION.to_enum)
        glLoadIdentity()
        glOrthof(0, renderSize.width.to_float, 0, renderSize.height.to_float, -1, 1)
        
        glMatrixMode(GL_MODELVIEW.to_enum)
        glLoadIdentity()
        
        renderBackground()
        
        glFramebufferTexture2D(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_TEXTURE_2D.to_enum, renderTexture, 0)
        
        context.presentRenderbuffer(GL_RENDERBUFFER.to_int)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_RENDERBUFFER.to_enum, 0)
        
        EAGLContext.setCurrent(nil)
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
        
        render()
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
    
    private func renderBackground() {
        var r = CGFloat(0), g = CGFloat(0), b = CGFloat(0)
        backgroundColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        
        glClearColor(r.to_clamp, g.to_clamp, b.to_clamp, 1)
        glClear(GL_COLOR_BUFFER_BIT.to_bitfield)
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
