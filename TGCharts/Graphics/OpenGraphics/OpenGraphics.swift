//
//  OpenGraphics.swift
//  TGCharts
//
//  Created by Stan Potemkin on 11/03/2019.
//  Copyright © 2019 bronenos. All rights reserved.
//

import Foundation
import UIKit

private let mostNearDepthZ = GLfloat(-10)
private let mostFarDepthZ = GLfloat(10)

final class OpenGraphics: IGraphics {
    private struct OutputMeta {
        let renderView: OpenGraphicsRenderView
        let parentView: UIView
        var nativeSize = CGSize.zero
        var renderSize = CGSize.zero
        var renderScale = CGFloat(0)
        var frameBuffer = GLuint(0)
        var renderBuffer = GLuint(0)
        var depthStencilBuffer = GLuint(0)
    }
    
    private struct NodeMeta {
        let frameBuffer: GLuint
        let texture: GLuint
        let pointSize: CGSize
        let scale: CGSize
    }
    
    private struct LabelMeta {
        let texture: GLuint
        let pointSize: CGSize
        let scale: CGSize
        let alignment: NSTextAlignment
    }
    
    private let context: EAGLContext
    private var outputMetas = [UUID: OutputMeta]()
    private var activeOutputMeta: OutputMeta?
    private var nodeMetas = [UUID: NodeMeta]()
    private var labelMetas = [UUID: LabelMeta]()
    
    private var clippingQueue = [CGRect]()
    
    private var alphaQueueValues = [CGFloat(1.0)]
    private var alphaResolvedValue = [CGFloat(1.0)]

    init(context: EAGLContext) {
        self.context = context
        
        EAGLContext.setCurrent(context)
    }
    
    deinit {
        outputMetas.values.forEach(discardOutput)
        outputMetas.removeAll()
        
        EAGLContext.setCurrent(nil)
    }
    
    var engineName: String {
        return "OpenGL"
    }
    
    func link(uuid: UUID, to view: UIView, delegate: IGraphicsDelegate) -> GraphicsOutputRef {
        if let meta = outputMetas[uuid] {
            if meta.nativeSize == view.bounds.size {
                return GraphicsOutputRef(outputUUID: uuid, graphics: self)
            }
            else {
                discardOutput(meta)
                
                nodeMetas.keys.forEach(discardTexture)
                labelMetas.keys.forEach(discardTexture)
            }
        }
        
        let renderView = OpenGraphicsRenderView()
        renderView.frame = view.bounds
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderView.delegate = delegate
        view.addSubview(renderView)
        
        let outputMeta = setupOutput(renderView: renderView, parentView: view)
        outputMetas[uuid] = outputMeta
        
        return GraphicsOutputRef(outputUUID: uuid, graphics: self)
    }
    
    func obtainCanvasSize(output: GraphicsOutputRef) -> CGSize {
        guard let outputMeta = outputMetas[output.outputUUID] else { return .zero }
        return outputMeta.nativeSize
    }
    
    func unlink(uuid: UUID, output: GraphicsOutputRef) {
        guard let outputMeta = outputMetas[uuid] else { return }
        discardOutput(outputMeta)
    }
    
    func pushOffset(_ offset: CGPoint) {
        glPushMatrix()
        glTranslatef(offset.x.scaled().to_float, offset.y.scaled().to_float, 0)
    }
    
    func popOffset() {
        glPopMatrix()
    }
    
    func render(output: GraphicsOutputRef, drawingBlock: (IGraphics) -> Void) {
        guard let outputMeta = outputMetas[output.outputUUID] else { return }
        
        activeOutputMeta = outputMeta
        defer { activeOutputMeta = nil }

        glBindFramebuffer(GL_FRAMEBUFFER.to_enum, outputMeta.frameBuffer)
        glViewport(0, 0, outputMeta.renderSize.width.to_size, outputMeta.renderSize.height.to_size)
        
        glMatrixMode(GL_PROJECTION.to_enum)
        glLoadIdentity()
        glOrthof(0, outputMeta.renderSize.width.to_float, 0, outputMeta.renderSize.height.to_float, mostNearDepthZ, mostFarDepthZ)
        
        glMatrixMode(GL_MODELVIEW.to_enum)
        glLoadIdentity()
        
        glEnable(GL_BLEND.to_enum)
        glBlendFunc(GL_SRC_ALPHA.to_enum, GL_ONE_MINUS_SRC_ALPHA.to_enum)
        
        drawingBlock(self)

        glBindRenderbuffer(GL_RENDERBUFFER.to_enum, outputMeta.renderBuffer)
        context.presentRenderbuffer(GL_RENDERBUFFER.toInt)
    }
    
    func pushMarker(caption: String) {
        glPushGroupMarkerEXT(0, caption)
    }
    
    func popMarker() {
        glPopGroupMarkerEXT()
    }
    
    func pushClippingArea(_ area: CGRect) {
        clippingQueue.append(area)
        applyResolvedClippingArea()
    }
    
    func popClippingArea() {
        clippingQueue.removeLast()
        applyResolvedClippingArea()
    }
    
    func pushAlpha(_ alpha: CGFloat) {
        let lastResolvedValue = resolvedAlpha
        let currentResolvedValue = lastResolvedValue * alpha
        
        alphaQueueValues.append(alpha)
        alphaResolvedValue.append(currentResolvedValue)
    }
    
    func popAlpha() {
        alphaQueueValues.removeLast()
        alphaResolvedValue.removeLast()
    }
    
    func clear(color: UIColor) {
        let c = color.extractComponents(extraBlended: 1.0)
        glClearColor(c.red.to_clamp, c.green.to_clamp, c.blue.to_clamp, c.alpha.to_clamp)
        glClear(GL_COLOR_BUFFER_BIT.to_bitfield)
    }
    
    func place(points: [CGPoint], color: UIColor, width: CGFloat) {
        let c = color.extractComponents(extraBlended: resolvedAlpha)
        glColor4f(c.red.to_float, c.green.to_float, c.blue.to_float, c.alpha.to_float)
        
        glEnable(GL_POINT_SMOOTH.to_enum)
        glHint(GL_POINT_SMOOTH_HINT.to_enum, GL_NICEST.to_enum)
        glPointSize(width.scaled().to_float)
        
        glEnableClientState(GL_VERTEX_ARRAY.to_enum);
        
        var depthIndex: GLfloat?
        let vertexCoords = convertPointsToValues(points, scalable: true, depthIndex: &depthIndex)
        glVertexPointer(3, GL_FLOAT.to_enum, 0, vertexCoords)
        glDrawArrays(GL_POINTS.to_enum, 0, points.count.to_size)
        
        glDisableClientState(GL_VERTEX_ARRAY.to_enum)
        
        glDisable(GL_POINT_SMOOTH.to_enum)
        glDisable(GL_BLEND.to_enum)
    }
    
    func stroke(points: [CGPoint], color: UIColor, width: CGFloat) {
        let lastIndex = points.count - 1
        guard lastIndex > 0 else { return }
        
        let innerSide = width * 0.3
        let outerSide = innerSide + 0.35
        let pointSize = outerSide * 1.75
        let outerColor = color.withAlphaComponent(0)
        
        glEnable(GL_BLEND.to_enum)
        
        glEnable(GL_POINT_SMOOTH.to_enum)
        glHint(GL_POINT_SMOOTH_HINT.to_enum, GL_NICEST.to_enum)
        glPointSize(pointSize.scaled().to_float)

        glEnableClientState(GL_VERTEX_ARRAY.to_enum);
        glEnableClientState(GL_COLOR_ARRAY.to_enum);
        
        var linesVertexCoords = [GLfloat]()
        var linesColorsCoords = [GLfloat]()
        var pointsVertexCoords = [GLfloat]()
        var pointsColorsCoords = [GLfloat]()
        var depthIndex: GLfloat?
        
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

            linesVertexCoords.append(
                contentsOf: convertPointsToValues(
                    vertexPoints,
                    scalable: true,
                    depthIndex: &depthIndex
                )
            )
            
            linesColorsCoords.append(
                contentsOf: convertColorsToValues(
                    vertexColors,
                    extraBlended: resolvedAlpha
                )
            )
            
            pointsVertexCoords.append(
                contentsOf: convertPointsToValues(
                    Array(vertexPoints[4 ... 5]),
                    scalable: true,
                    depthIndex: &depthIndex
                )
            )

            pointsColorsCoords.append(
                contentsOf: convertColorsToValues(
                    Array(vertexColors[4 ... 5]),
                    extraBlended: resolvedAlpha
                )
            )
        }
        
        func _draw() {
            glVertexPointer(3, GL_FLOAT.to_enum, 0, linesVertexCoords)
            glColorPointer(4, GL_FLOAT.to_enum, 0, linesColorsCoords)
            glDrawArrays(GL_TRIANGLE_STRIP.to_enum, 0, linesVertexCoords.count.to_size / 3)
            
            glVertexPointer(3, GL_FLOAT.to_enum, 0, pointsVertexCoords)
            glColorPointer(4, GL_FLOAT.to_enum, 0, pointsColorsCoords)
            glDrawArrays(GL_POINTS.to_enum, 0, pointsVertexCoords.count.to_size / 3)
        }
        
//        glEnable(GL_DEPTH_TEST.to_enum)
//        glClear(GL_DEPTH_BUFFER_BIT.to_bitfield)
//        glColorMask(GL_FALSE.to_boolean, GL_FALSE.to_boolean, GL_FALSE.to_boolean, GL_FALSE.to_boolean)
        _draw()
//        glColorMask(GL_TRUE.to_boolean, GL_TRUE.to_boolean, GL_TRUE.to_boolean, GL_TRUE.to_boolean)
//        glDepthFunc(GL_LEQUAL.to_enum)
//        _draw()
//        glDisable(GL_DEPTH_TEST.to_enum)

        glDisableClientState(GL_VERTEX_ARRAY.to_enum)
        glDisableClientState(GL_COLOR_ARRAY.to_enum)
        
        glDisable(GL_POINT_SMOOTH.to_enum)
        glDisable(GL_BLEND.to_enum)
    }
    
    func fill(frame: CGRect, color: UIColor) {
        let c = color.extractComponents(extraBlended: resolvedAlpha)
        glColor4f(c.red.to_float, c.green.to_float, c.blue.to_float, c.alpha.to_float)
        
        glEnable(GL_BLEND.to_enum)

        glEnableClientState(GL_VERTEX_ARRAY.to_enum)
        
        let vertexPoints: [CGPoint] = [
            frame.topLeftPoint,
            frame.bottomLeftPoint,
            frame.topRightPoint,
            frame.bottomRightPoint
        ]

        var depthIndex: GLfloat?
        let vertexCoords = convertPointsToValues(vertexPoints, scalable: true, depthIndex: &depthIndex)
        glVertexPointer(3, GL_FLOAT.to_enum, 0, vertexCoords)
        glDrawArrays(GL_TRIANGLE_STRIP.to_enum, 0, vertexPoints.count.to_size)
        
        glDisableClientState(GL_VERTEX_ARRAY.to_enum)
        
        glDisable(GL_BLEND.to_enum)
    }
    
    func isValidTexture(_ texture: GraphicsTextureRef) -> Bool {
        if let _ = nodeMetas[texture.textureUUID] { return true }
        if let _ = labelMetas[texture.textureUUID] { return true }
        return false
    }
    
    func requestNodeTexture(size: CGSize) -> GraphicsTextureRef? {
        guard let outputMeta = activeOutputMeta else { return nil }
        
        var textureID = GLuint(0)
        glGenTextures(1, &textureID)
        guard textureID > 0 else { return nil }
        
//        NSLog("\(#function) -> texture[\(textureID)] pre-status[\(glIsTexture(textureID))]")
        
        glBindTexture(GL_TEXTURE_2D.to_enum, textureID)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_MIN_FILTER.to_enum, GL_LINEAR.to_float)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_MAG_FILTER.to_enum, GL_LINEAR.to_float)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_WRAP_S.to_enum, GL_CLAMP_TO_EDGE.to_float)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_WRAP_T.to_enum, GL_CLAMP_TO_EDGE.to_float)
        
        let renderWidth = size.width * outputMeta.renderScale
        let renderHeight = size.height * outputMeta.renderScale
        let textureWidth = calculateCoveringDuoPower(value: Int(renderWidth))
        let textureHeight = calculateCoveringDuoPower(value: Int(renderHeight))

//        glBindBuffer(GL_PIXEL_UNPACK_BUFFER.to_enum, 0)
//        glPixelStorei(GL_UNPACK_ALIGNMENT.to_enum, 1)
        
        glTexImage2D(
            GL_TEXTURE_2D.to_enum, 0, GL_RGBA.to_int,
            textureWidth.to_size, textureHeight.to_size, 0,
            GL_RGBA.to_enum, GL_UNSIGNED_BYTE.to_enum,
            nil
        )
        
        var textureFrameBuffer = GLuint(0)
        glGenFramebuffers(1, &textureFrameBuffer)
        guard textureFrameBuffer > 0 else { return nil }

        glBindFramebuffer(GL_FRAMEBUFFER.to_enum, textureFrameBuffer)
        glFramebufferTexture2D(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_TEXTURE_2D.to_enum, textureID, 0)
        glViewport(0, 0, renderWidth.to_size, renderHeight.to_size)
        
        glMatrixMode(GL_PROJECTION.to_enum)
        glPushMatrix()
        glLoadIdentity()
        glOrthof(0, renderWidth.to_float, 0, renderHeight.to_float, -1, 1)
        
        glMatrixMode(GL_MODELVIEW.to_enum)
        glPushMatrix()
        glLoadIdentity()
        glScalef(1, -1, 1)
        glTranslatef(0, -renderHeight.to_float, 0)

        clear(color: UIColor.clear)
        
        let uuid = UUID()
        nodeMetas[uuid] = NodeMeta(
            frameBuffer: textureFrameBuffer,
            texture: textureID,
            pointSize: size,
            scale: CGSize(
                width: renderWidth / CGFloat(textureWidth),
                height: renderHeight / CGFloat(textureHeight)
            )
        )
        
        return GraphicsTextureRef(textureUUID: uuid, graphics: self)
    }
    
    func flushNodeTexture(_ texture: GraphicsTextureRef) {
        glMatrixMode(GL_PROJECTION.to_enum)
        glPopMatrix()
        
        glMatrixMode(GL_MODELVIEW.to_enum)
        glPopMatrix()
    }
    
    func drawNodeTexture(_ texture: GraphicsTextureRef) {
        guard let outputMeta = activeOutputMeta else { return }
        
        glBindFramebuffer(GL_FRAMEBUFFER.to_enum, outputMeta.frameBuffer)
        glViewport(0, 0, outputMeta.renderSize.width.to_size, outputMeta.renderSize.height.to_size)
        
        guard let nodeMeta = nodeMetas[texture.textureUUID] else { return }
        let frame = CGRect(origin: .zero, size: nodeMeta.pointSize)
        
        let c = UIColor.white.extractComponents(extraBlended: 1.0)
        glColor4f(c.red.to_float, c.green.to_float, c.blue.to_float, c.alpha.to_float)
        
        glEnable(GL_BLEND.to_enum)

        glBindTexture(GL_TEXTURE_2D.to_enum, nodeMeta.texture)
        glEnable(GL_TEXTURE_2D.to_enum)
        
        glEnableClientState(GL_VERTEX_ARRAY.to_enum)
        glEnableClientState(GL_TEXTURE_COORD_ARRAY.to_enum)
        
        let vertexPoints: [CGPoint] = [
            frame.topLeftPoint,
            frame.bottomLeftPoint,
            frame.topRightPoint,
            frame.bottomRightPoint
        ]
        
        let textureScaling = CGRect(
            x: 0,
            y: 0,
            width: nodeMeta.scale.width,
            height: nodeMeta.scale.height
        )
        
        let texturePoints: [CGPoint] = [
            textureScaling.bottomLeftPoint,
            textureScaling.topLeftPoint,
            textureScaling.bottomRightPoint,
            textureScaling.topRightPoint
        ]
        
        var depthIndex: GLfloat?
        let vertexCoords = convertPointsToValues(vertexPoints, scalable: true, depthIndex: &depthIndex)
        let textureCoords = convertPointsToValues(texturePoints, scalable: false, depthIndex: &depthIndex)
        glVertexPointer(3, GL_FLOAT.to_enum, 0, vertexCoords)
        glTexCoordPointer(3, GL_FLOAT.to_enum, 0, textureCoords)
        glDrawArrays(GL_TRIANGLE_STRIP.to_enum, 0, vertexPoints.count.to_size)
        
        glDisableClientState(GL_VERTEX_ARRAY.to_enum)
        glDisableClientState(GL_TEXTURE_COORD_ARRAY.to_enum)
        
        glBindTexture(GL_TEXTURE_2D.to_enum, 0)
        glDisable(GL_TEXTURE_2D.to_enum)
        
        glDisable(GL_BLEND.to_enum)
    }
    
    func storeLabelTexture(meta: GraphicsTextureMeta) -> GraphicsTextureRef? {
        var textureID = GLuint(0)
        glGenTextures(1, &textureID)
        guard textureID > 0 else { return nil }
        
        glBindTexture(GL_TEXTURE_2D.to_enum, textureID)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_MIN_FILTER.to_enum, GL_LINEAR.to_float)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_MAG_FILTER.to_enum, GL_LINEAR.to_float)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_WRAP_S.to_enum, GL_CLAMP_TO_EDGE.to_float)
        glTexParameterf(GL_TEXTURE_2D.to_enum, GL_TEXTURE_WRAP_T.to_enum, GL_CLAMP_TO_EDGE.to_float)

        glTexImage2D(
            GL_TEXTURE_2D.to_enum, 0, GL_RGBA.to_int,
            meta.textureSize.width.to_size, meta.textureSize.height.to_size, 0,
            GL_RGBA.to_enum, GL_UNSIGNED_BYTE.to_enum,
            meta.bytes
        )

        let uuid = UUID()
        labelMetas[uuid] = LabelMeta(
            texture: textureID,
            pointSize: meta.pointSize,
            scale: CGSize(
                width: meta.pixelSize.width / meta.textureSize.width,
                height: meta.pixelSize.height / meta.textureSize.height
            ),
            alignment: meta.alignment
        )
        
        return GraphicsTextureRef(textureUUID: uuid, graphics: self)
    }
    
    func drawLabelTexture(_ texture: GraphicsTextureRef, in frame: CGRect) {
        guard let meta = labelMetas[texture.textureUUID] else { return }
        
        let c = UIColor.white.extractComponents(extraBlended: resolvedAlpha)
        glColor4f(c.red.to_float, c.green.to_float, c.blue.to_float, c.alpha.to_float)
        
        glEnable(GL_BLEND.to_enum)

        glBindTexture(GL_TEXTURE_2D.to_enum, meta.texture)
        glEnable(GL_TEXTURE_2D.to_enum)

        glEnableClientState(GL_VERTEX_ARRAY.to_enum)
        glEnableClientState(GL_TEXTURE_COORD_ARRAY.to_enum)
        
        let topMargin = (frame.height - min(frame.height, meta.pointSize.height)) * 0.5
        let bottomMargin = topMargin
        let leftMargin, rightMargin: CGFloat
        
        switch meta.alignment {
        case .left:
            leftMargin = 0
            rightMargin = frame.width - meta.pointSize.width
            
        case .right:
            rightMargin = 0
            leftMargin = frame.width - meta.pointSize.width

        default:
            abort()
        }

        let alignedFrame = frame.inset(
            by: UIEdgeInsets(top: topMargin, left: leftMargin, bottom: bottomMargin, right: rightMargin)
        )

        let vertexPoints: [CGPoint] = [
            alignedFrame.topLeftPoint,
            alignedFrame.bottomLeftPoint,
            alignedFrame.topRightPoint,
            alignedFrame.bottomRightPoint
        ]
        
        let textureScaling = CGRect(
            x: 0,
            y: 1.0 - meta.scale.height,
            width: meta.scale.width,
            height: meta.scale.height
        )
        
        let texturePoints: [CGPoint] = [
            textureScaling.bottomLeftPoint,
            textureScaling.topLeftPoint,
            textureScaling.bottomRightPoint,
            textureScaling.topRightPoint
        ]
        
        var depthIndex: GLfloat?
        let vertexCoords = convertPointsToValues(vertexPoints, scalable: true, depthIndex: &depthIndex)
        let textureCoords = convertPointsToValues(texturePoints, scalable: false, depthIndex: &depthIndex)
        glVertexPointer(3, GL_FLOAT.to_enum, 0, vertexCoords)
        glTexCoordPointer(3, GL_FLOAT.to_enum, 0, textureCoords)
        glDrawArrays(GL_TRIANGLE_STRIP.to_enum, 0, vertexPoints.count.to_size)
        
        glDisableClientState(GL_VERTEX_ARRAY.to_enum)
        glDisableClientState(GL_TEXTURE_COORD_ARRAY.to_enum)

        glBindTexture(GL_TEXTURE_2D.to_enum, 0)
        glDisable(GL_TEXTURE_2D.to_enum)
        
        glDisable(GL_BLEND.to_enum)
    }
    
    func discardTexture(_ texture: GraphicsTextureRef) {
        discardTexture(texture.textureUUID)
    }
    
    func discardTexture(_ uuid: UUID) {
        if let meta = nodeMetas.removeValue(forKey: uuid) {
            glBindFramebuffer(GL_FRAMEBUFFER.to_enum, 0)
            glDeleteFramebuffers(1, [meta.frameBuffer])
            
            glBindTexture(GL_TEXTURE_2D.to_enum, 0)
            glDeleteTextures(1, [meta.texture])
        }
        else if let meta = labelMetas.removeValue(forKey: uuid) {
            glBindTexture(GL_TEXTURE_2D.to_enum, 0)
            glDeleteTextures(1, [meta.texture])
        }
    }

    private func setupOutput(renderView: OpenGraphicsRenderView, parentView: UIView) -> OutputMeta {
        let nativeSize = renderView.bounds.size
        let renderScale = UIScreen.main.scale
        let renderSize = CGSize(width: nativeSize.width * renderScale, height: nativeSize.height * renderScale)
        
        var renderBuffer = GLuint(0)
        glGenRenderbuffers(1, &renderBuffer)
        guard renderBuffer > 0 else { abort() }
        
        glBindRenderbuffer(GL_RENDERBUFFER.to_enum, renderBuffer)
        context.renderbufferStorage(GL_RENDERBUFFER.toInt, from: renderView.drawableLayer)

        var frameBuffer = GLuint(0)
        glGenFramebuffers(1, &frameBuffer)
        guard frameBuffer > 0 else { abort() }
        
        glBindFramebuffer(GL_FRAMEBUFFER.to_enum, frameBuffer)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER.to_enum, GL_COLOR_ATTACHMENT0.to_enum, GL_RENDERBUFFER.to_enum, renderBuffer)
        
        var depthStencilBuffer = GLuint(0)
        glGenRenderbuffers(1, &depthStencilBuffer)
        guard depthStencilBuffer > 0 else { abort() }
        glBindRenderbuffer(GL_RENDERBUFFER.to_enum, depthStencilBuffer)
        glRenderbufferStorage(GL_RENDERBUFFER.to_enum, GL_DEPTH24_STENCIL8.to_enum, renderSize.width.to_size, renderSize.height.to_size)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER.to_enum, GL_DEPTH_STENCIL_ATTACHMENT.to_enum, GL_RENDERBUFFER.to_enum, depthStencilBuffer)
        
        return OutputMeta(
            renderView: renderView,
            parentView: parentView,
            nativeSize: nativeSize,
            renderSize: renderSize,
            renderScale: renderScale,
            frameBuffer: frameBuffer,
            renderBuffer: renderBuffer,
            depthStencilBuffer: depthStencilBuffer
        )
    }
    
    private func discardOutput(_ output: OutputMeta) {
        output.renderView.removeFromSuperview()
        
        glBindFramebuffer(GL_FRAMEBUFFER.to_enum, 0)
        glDeleteFramebuffers(1, [output.frameBuffer])

        glBindRenderbuffer(GL_RENDERBUFFER.to_enum, 0)
        glDeleteRenderbuffers(2, [output.renderBuffer, output.depthStencilBuffer])
    }
    
    private func applyResolvedClippingArea() {
        if let area = clippingQueue.last {
            glEnable(GL_STENCIL_TEST.to_enum)
            glClear(GL_STENCIL_BUFFER_BIT.to_bitfield)
            
            glStencilFunc(GL_ALWAYS.to_enum, 1, 0)
            glStencilOp(GL_KEEP.to_enum, GL_KEEP.to_enum, GL_REPLACE.to_enum)
            fill(frame: area, color: UIColor.clear)

            glStencilFunc(GL_EQUAL.to_enum, 1, ~0)
            glStencilOp(GL_KEEP.to_enum, GL_KEEP.to_enum, GL_KEEP.to_enum)
        }
        else {
            glDisable(GL_STENCIL_TEST.to_enum)
        }
    }
    
    private var resolvedAlpha: CGFloat {
        return alphaResolvedValue.last ?? 1.0
    }
    
    private func convertPointsToValues(_ points: [CGPoint], scalable: Bool, depthIndex: inout GLfloat?) -> [GLfloat] {
        var values = [GLfloat](repeating: 0, count: points.count * 3)
        var index = 0
        
        points.forEach { point in
//            let depth: GLfloat
//            if let index = depthIndex {
//                if index >= 0 {
//                    depth = mostNearDepthZ
//                }
//                else {
//                    depth = index + 0.01
//                }
//            }
//            else {
//                depth = mostNearDepthZ
//            }
            
            if scalable {
                values[index] = point.x.scaled().to_float
                index += 1
                
                values[index] = point.y.scaled().to_float
                index += 1
                
                values[index] = 0
                index += 1
            }
            else {
                values[index] = point.x.to_float
                index += 1
                
                values[index] = point.y.to_float
                index += 1
                
                values[index] = 0
                index += 1
            }
            
//            depthIndex = depth
        }
        
        return values
    }
    
    private func convertColorsToValues(_ colors: [UIColor], extraBlended alpha: CGFloat) -> [GLfloat] {
        var values = [GLfloat](repeating: 0, count: colors.count * 4)
        var index = 0
        
        func _extractColorComponents(_ color: UIColor) -> UIColor.Components {
            return color.extractComponents(extraBlended: alpha)
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
    var scaled: Int {
        return self * Int(UIScreen.main.scale)
    }
    
    var to_size: GLsizei {
        return GLsizei(self)
    }
}

fileprivate extension Int32 {
    var toInt: Int {
        return Int(self)
    }
    
    var to_int: GLint {
        return GLint(self)
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
    
    var to_boolean: GLboolean {
        return GLboolean(self)
    }
}

fileprivate extension CGFloat {
    func scaled() -> CGFloat {
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
    
    func extractComponents(extraBlended alpha: CGFloat) -> Components {
        var c = Components()
        getRed(&c.red, green: &c.green, blue: &c.blue, alpha: &c.alpha)
        c.alpha *= alpha
        return c
    }
}
