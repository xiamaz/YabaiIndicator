//
//  ImageGenerator.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 29/12/2021.
//
import Foundation
import Cocoa
import SwiftUI

private func drawText(symbol: NSString, color: NSColor, size: CGSize) {
    let fontSize:CGFloat = 11

    let attrs:[NSAttributedString.Key : Any] = [.font: NSFont.systemFont(ofSize: fontSize), .foregroundColor: color]
    let boundingBox = symbol.size(withAttributes: attrs)
    let x:CGFloat = size.width / 2 - boundingBox.width / 2
    let y:CGFloat = size.height / 2 - boundingBox.height / 2

    symbol.draw(at: NSPoint(x: x, y: y), withAttributes: [.font: NSFont.systemFont(ofSize: fontSize), .foregroundColor: color])
}

func generateImage(symbol: NSString, active: Bool, visible: Bool) -> NSImage {
    let size = CGSize(width: 24, height: 16)
    let cornerRadius:CGFloat = 6
    
    let canvas = NSRect(origin: CGPoint.zero, size: size)
    
    let image = NSImage(size: size)
    let strokeColor = NSColor.black
    
    if active || visible{
        let imageFill = NSImage(size: size)
        let imageStroke = NSImage(size: size)

        imageFill.lockFocus()
        strokeColor.setFill()
        NSBezierPath(roundedRect: canvas, xRadius: cornerRadius, yRadius: cornerRadius).fill()
        imageFill.unlockFocus()
        imageStroke.lockFocus()
        drawText(symbol: symbol, color: strokeColor, size: size)
        imageStroke.unlockFocus()
        
        image.lockFocus()
        imageFill.draw(in: canvas, from: NSZeroRect, operation: .sourceOut, fraction: active ? 1.0 : 0.8)
        imageStroke.draw(in: canvas, from: NSZeroRect, operation: .destinationOut, fraction: active ? 1.0 : 0.8)
        image.unlockFocus()
    } else {
        image.lockFocus()
        strokeColor.setStroke()
        let path = NSBezierPath(roundedRect: canvas.insetBy(dx: 0.5, dy: 0.5), xRadius: cornerRadius, yRadius: cornerRadius)
        path.stroke()
        drawText(symbol: symbol, color: strokeColor, size: size)
        image.unlockFocus()
    }
    image.isTemplate = true
    return image
}

func drawWindows(in content: NSRect, windows: [Window], display: Display) {
    let displaySize = display.frame.size
    let displayOrigin = display.frame.origin
    let contentSize = content.size
    let contentOrigin = content.origin
    let scaling = displaySize.height > displaySize.width ? displaySize.height / contentSize.height : displaySize.width / contentSize.width
    let xoffset = (displaySize.height > displaySize.width ? (contentSize.width - displaySize.width / scaling) / 2 : 0) + contentOrigin.x
    let yoffset = (displaySize.height > displaySize.width ? 0 : (contentSize.height - displaySize.height / scaling) / 2) + contentOrigin.y
    
    let scalingFactor = 1/scaling
    let transform = NSAffineTransform()
    transform.scale(by: scalingFactor)
    transform.translateX(by: xoffset / scalingFactor, yBy: yoffset / scalingFactor)
    // plot single windows
    for window in windows.reversed() {
        let fixedOrigin = NSPoint(x: window.frame.origin.x - displayOrigin.x, y: displaySize.height - (window.frame.origin.y - displayOrigin.y + window.frame.height))
        let windowOrigin = transform.transform(fixedOrigin)
        let windowSize = transform.transform(window.frame.size)
        let windowRect = NSRect(origin: windowOrigin, size: windowSize)
        let windowPath = NSBezierPath(rect: windowRect)
        windowPath.fill()
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.compositingOperation = .destinationOut
        windowPath.lineWidth = 1.5
        windowPath.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
}

func generateImage(active: Bool, visible: Bool, windows: [Window], display: Display) -> NSImage {
    let size = CGSize(width: 24, height: 16)
    let canvas = NSRect(origin: CGPoint.zero, size: size)
    let bounds = NSBezierPath(rect: canvas.insetBy(dx: 4, dy: 4))
    let cornerRadius:CGFloat = 6
    
    
    let image = NSImage(size: size)
    let strokeColor = NSColor.black
    
    if active || visible{
        let imageFill = NSImage(size: size)
        let imageStroke = NSImage(size: size)

        imageFill.lockFocus()
        strokeColor.setFill()
        NSBezierPath(roundedRect: canvas, xRadius: cornerRadius, yRadius: cornerRadius).fill()
        imageFill.unlockFocus()
        
        imageStroke.lockFocus()
        drawWindows(in: canvas, windows: windows, display: display)
        imageStroke.unlockFocus()
        
        image.lockFocus()
        imageFill.draw(in: canvas, from: NSZeroRect, operation: .sourceOut, fraction: active ? 1.0 : 0.8)
        
        bounds.setClip()
        imageStroke.draw(in: canvas, from: NSZeroRect, operation: .destinationOut, fraction: active ? 1.0 : 0.8)
        image.unlockFocus()
    } else {
        image.lockFocus()
        strokeColor.setStroke()
        NSBezierPath(roundedRect: canvas.insetBy(dx: 0.5, dy: 0.5), xRadius: cornerRadius, yRadius: cornerRadius).stroke()

        bounds.setClip()
        drawWindows(in: canvas, windows: windows, display: display)
        image.unlockFocus()
    }
    image.isTemplate = true
    return image
}
