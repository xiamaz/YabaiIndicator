//
//  ImageGenerator.swift
//  YabaiIndicator
//
//  Created by Max Zhao on 29/12/2021.
//
import Foundation
import Cocoa

func generateImage(symbol: NSString, active: Bool, visible: Bool) -> NSImage {
    let width = 24
    let height = 16
    let size = CGSize(width: width, height: height)
    let canvas = NSRect(x: 0, y: 0, width: width, height: height)
    let image = NSImage(size: size)
    let imageFill = NSImage(size: size)
    let imageStroke = NSImage(size: size)
    
    let strokeColor = NSColor.black
    if active || visible{
        imageFill.lockFocus()
        strokeColor.setFill()
        NSBezierPath(roundedRect: canvas, xRadius: 6, yRadius: 6).fill()
        imageFill.unlockFocus()
        imageStroke.lockFocus()
        symbol.draw(in: NSRect(x: 9, y: -1, width: 16, height: 16), withAttributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: strokeColor])
        imageStroke.unlockFocus()
        
        image.lockFocus()
        imageFill.draw(in: canvas, from: NSZeroRect, operation: .sourceOut, fraction: 1.0)
        imageStroke.draw(in: canvas, from: NSZeroRect, operation: .destinationOut, fraction: active ? 1.0 : 0.5)
        image.unlockFocus()
    } else {
        image.lockFocus()
        strokeColor.setStroke()
        NSBezierPath(roundedRect: canvas, xRadius: 6, yRadius: 6).stroke()
        symbol.draw(in: NSRect(x: 9, y: -1, width: 16, height: 16), withAttributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: strokeColor])
        image.unlockFocus()

    }
    image.isTemplate = true
    return image
}
