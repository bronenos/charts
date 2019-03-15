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
    private var generalFrameBuffer = GLuint(0)
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
    
    func setDelegate(_ delegate: IGraphicsDelegate?) {
        renderView.delegate = delegate
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
    
    func pushOffset(_ offset: CGPoint) {
        glPushMatrix()
        glTranslatef(offset.x.scaled.to_float, offset.y.scaled.to_float, 0)
    }
    
    func popOffset() {
        glPopMatrix()
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
        
//        glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE.to_enum, generalFrameBuffer)
//        glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE.to_enum, msaaFrameBuffer)
//        glResolveMultisampleFramebufferAPPLE()
        
        glFramebufferTexture2D(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_TEXTURE_2D.to_enum, renderTexture, 0)
        context.presentRenderbuffer(GL_RENDERBUFFER.to_int)
        
        EAGLContext.setCurrent(nil)
    }
    
    func clear(color: UIColor) {
        let c = color.extractComponents()
        glClearColor(c.red.to_clamp, c.green.to_clamp, c.blue.to_clamp, c.alpha.to_clamp)
        glClear(GL_COLOR_BUFFER_BIT.to_bitfield)
    }
    
    func stroke(points: [CGPoint], color: UIColor, width: CGFloat) {
        let lastIndex = points.count - 1
        guard lastIndex > 0 else { return }
        
        let innerSide = width * 0.3
        let outerSide = innerSide + 0.35
        let pointSize = outerSide * 1.75
        let outerColor = color.withAlphaComponent(0)
        
        glEnable(GL_POINT_SMOOTH.to_enum)
        glHint(GL_POINT_SMOOTH_HINT.to_enum, GL_NICEST.to_enum)
        glPointSize(pointSize.scaled.to_float)

        glEnable(GL_BLEND.to_enum)
        glBlendFunc(GL_SRC_ALPHA.to_enum, GL_ONE_MINUS_SRC_ALPHA.to_enum)
        
        glEnableClientState(GL_VERTEX_ARRAY.to_enum);
        glEnableClientState(GL_COLOR_ARRAY.to_enum);
        
        for i in (0 ..< lastIndex) {
            let pointFrom = points[i]
            let pointTo = points[i + 1]

            let horDistance = abs(pointTo.x - pointFrom.x)
            let verDistance = abs(pointTo.y - pointFrom.y)
            let totalDistance = sqrt(horDistance * horDistance + verDistance * verDistance)
            guard totalDistance > 0 else { continue }

            let horDirection = CGFloat(pointTo.y >= pointFrom.y ? -1 : 1)
            let horMult = horDirection * (0.5 + cos(.pi / 2 * horDistance / totalDistance))
            
            let verDirection = CGFloat(pointTo.x >= pointFrom.x ? 1 : -1)
            let verMult = verDirection * (0.5 + cos(.pi / 2 * verDistance / totalDistance))

            let vertexPoints: [CGPoint] = [
                pointFrom + CGVector(dx: outerSide * horMult, dy: outerSide * verMult),
                pointTo + CGVector(dx: outerSide * horMult, dy: outerSide * verMult),
                pointFrom + CGVector(dx: innerSide * horMult, dy: innerSide * verMult),
                pointTo + CGVector(dx: innerSide * horMult, dy: innerSide * verMult),
                pointFrom,
                pointTo,
                pointFrom + CGVector(dx: innerSide * -horMult, dy: innerSide * -verMult),
                pointTo + CGVector(dx: innerSide * -horMult, dy: innerSide * -verMult),
                pointFrom + CGVector(dx: outerSide * -horMult, dy: outerSide * -verMult),
                pointTo + CGVector(dx: outerSide * -horMult, dy: outerSide * -verMult)
            ]

            let vertexColors: [UIColor] = [
                outerColor,
                outerColor,
                color,
                color,
                color,
                color,
                color,
                color,
                outerColor,
                outerColor
            ]

            let coords = convertPointsToValues(vertexPoints)
            let colors = convertColorsToValues(vertexColors)
            glVertexPointer(2, GL_FLOAT.to_enum, 0, coords)
            glColorPointer(4, GL_FLOAT.to_enum, 0, colors)
            glDrawArrays(GL_TRIANGLE_STRIP.to_enum, 0, vertexPoints.count.to_size)
            glDrawArrays(GL_POINTS.to_enum, 4, 2)
        }
        
        glDisableClientState(GL_VERTEX_ARRAY.to_enum)
        glDisableClientState(GL_COLOR_ARRAY.to_enum)
        
        glDisable(GL_POINT_SMOOTH.to_enum)
        glDisable(GL_BLEND.to_enum)
    }
    
    func fill(frame: CGRect, color: UIColor) {
        let c = color.extractComponents()
        glColor4f(c.red.to_float, c.green.to_float, c.blue.to_float, c.alpha.to_float)
        
        glEnable(GL_BLEND.to_enum)
        glBlendFunc(GL_SRC_ALPHA.to_enum, GL_ONE_MINUS_SRC_ALPHA.to_enum)
        
        glEnableClientState(GL_VERTEX_ARRAY.to_enum)
        
        let vertexPoints: [CGPoint] = [
            CGPoint(x: frame.maxX, y: frame.minY), // bottom-right
            CGPoint(x: frame.maxX, y: frame.maxY), // top-right
            CGPoint(x: frame.minX, y: frame.minY), // bottom-left
            CGPoint(x: frame.minX, y: frame.maxY) // top-left
        ]

        let coords = convertPointsToValues(
            vertexPoints
        )
        
        glVertexPointer(2, GL_FLOAT.to_enum, 0, coords)
        glDrawArrays(GL_TRIANGLE_STRIP.to_enum, 0, vertexPoints.count.to_size)
        
        glDisableClientState(GL_VERTEX_ARRAY.to_enum)
        
        glDisable(GL_BLEND.to_enum)
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
        
        glGenFramebuffers(1, &generalFrameBuffer)
//        glGenFramebuffers(1, &msaaFrameBuffer)
        if generalFrameBuffer > 0 {
            glBindFramebuffer(GL_FRAMEBUFFER.to_enum, generalFrameBuffer)
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
        
        EAGLContext.setCurrent(nil)
    }
    
    private func closeEnvironment() {
        EAGLContext.setCurrent(context)
        
        glBindFramebuffer(GL_FRAMEBUFFER.to_enum, 0)
        glDeleteFramebuffers(1, &generalFrameBuffer)
        generalFrameBuffer = 0

        glBindRenderbuffer(GL_RENDERBUFFER.to_enum, 0)
        glDeleteRenderbuffers(1, &renderBuffer)
        renderBuffer = 0
        
        glBindTexture(GL_TEXTURE_2D.to_enum, 0)
        glDeleteTextures(1, &renderTexture)
        renderTexture = 0
        
        EAGLContext.setCurrent(nil)
    }
    
    private func convertPointsToValues(_ points: [CGPoint]) -> [GLfloat] {
        var values = [GLfloat](repeating: 0, count: points.count * 2)
        var index = 0
        
        points.forEach { point in
            values[index] = point.x.scaled.to_float
            index += 1
            
            values[index] = point.y.scaled.to_float
            index += 1
        }
        
        return values
    }
    
    private func convertColorsToValues(_ colors: [UIColor]) -> [GLfloat] {
        var values = [GLfloat](repeating: 0, count: colors.count * 4)
        var index = 0
        
        func _extractColorComponents(_ color: UIColor) -> UIColor.Components {
            return color.extractComponents()
        }

        colors.map(_extractColorComponents).forEach { components in
            values[index] = components.red.to_float
            index += 1
            
            values[index] = components.green.to_float
            index += 1
            
            values[index] = components.blue.to_float
            index += 1
            
            values[index] = components.alpha.to_float
            index += 1
        }
        
        return values
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
    var scaled: CGFloat {
        return self * UIScreen.main.scale
    }
    
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

fileprivate extension UIColor {
    struct Components {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
    }
    
    func extractComponents() -> Components {
        var c = Components()
        getRed(&c.red, green: &c.green, blue: &c.blue, alpha: &c.alpha)
        return c
    }
}
