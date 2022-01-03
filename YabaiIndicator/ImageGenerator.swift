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

func drawWindows(contentSize: CGSize, contentXOffset: Double, contentYOffset: Double, windows: [Window], display: Display) {
    let scaling = display.size.height > display.size.width ? display.size.height / contentSize.height : display.size.width / contentSize.width
    let xoffset = (display.size.height > display.size.width ? (contentSize.width - display.size.width / scaling) / 2 : 0) + contentXOffset
    let yoffset = (display.size.height > display.size.width ? 0 : (contentSize.height - display.size.height / scaling) / 2) + contentYOffset
    
    let scalingFactor = 1/scaling
    let transform = NSAffineTransform()
    transform.scale(by: scalingFactor)
    transform.translateX(by: xoffset / scalingFactor, yBy: yoffset / scalingFactor)
    // plot single windows
    for window in windows {
        let windowInset = 0.8
        let fixedSize = NSSize(width: window.frame.width * windowInset, height: window.frame.height * windowInset)
        let fixedOrigin = NSPoint(x: window.frame.origin.x + (window.frame.width - fixedSize.width) / 2, y: display.size.height - (window.frame.origin.y + window.frame.height) + (window.frame.height - fixedSize.height) / 2)
        let windowOrigin = transform.transform(fixedOrigin)
        let windowSize = transform.transform(fixedSize)
        let windowRect = NSBezierPath(rect: NSRect(origin: windowOrigin, size: windowSize))
        windowRect.fill()
    }
}

func generateImage(active: Bool, visible: Bool, windows: [Window], display: Display) -> NSImage {
    let size = CGSize(width: 24, height: 16)
    let contentYOffset = 4.0
    let contentXOffset = 4.0
    let contentSize = CGSize(width: size.width - contentXOffset * 2, height: size.height - contentYOffset * 2)
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
        drawWindows(contentSize: contentSize, contentXOffset: contentXOffset, contentYOffset: contentYOffset, windows: windows, display: display)
        imageStroke.unlockFocus()
        
        image.lockFocus()
        imageFill.draw(in: canvas, from: NSZeroRect, operation: .sourceOut, fraction: active ? 1.0 : 0.8)
        imageStroke.draw(in: canvas, from: NSZeroRect, operation: .destinationOut, fraction: active ? 1.0 : 0.8)
        image.unlockFocus()
    } else {
        image.lockFocus()
        strokeColor.setStroke()
        NSBezierPath(roundedRect: canvas.insetBy(dx: 0.5, dy: 0.5), xRadius: cornerRadius, yRadius: cornerRadius).stroke()
        drawWindows(contentSize: contentSize, contentXOffset: contentXOffset, contentYOffset: contentYOffset, windows: windows, display: display)
        image.unlockFocus()
    }
    image.isTemplate = true
    return image
}
