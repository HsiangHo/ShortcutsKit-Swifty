//
//  SCKeyComboView.swift
//  ShortcutsKitSwifty
//
//  Created by Jovi on 12/8/19.
//  Copyright © 2019 Jovi. All rights reserved.
//

import Cocoa
import Carbon

public protocol SCKeyComboViewDelegate: class {
    func keyComboWillChange(keyComboView: SCKeyComboView)
    func keyComboDidChange(keyComboView: SCKeyComboView)
}

extension SCKeyComboViewDelegate {
    func keyComboWillChange(keyComboView: SCKeyComboView) {
    }

    func keyComboDidChange(keyComboView: SCKeyComboView) {
    }
}

public class SCKeyComboView: NSView {
    public weak var delegate: SCKeyComboViewDelegate?
    public var hotKey: SCHotkey?
    public var backgroundColor: NSColor = NSColor.clear
    public var hoveredBackgroundColor: NSColor = NSColor.white
    public var borderColor: NSColor = NSColor.clear
    public var hoveredBorderColor: NSColor = NSColor.lightGray
    public var onTintColor: NSColor = NSColor.init(calibratedRed: 0, green: 126/255.0, blue: 200/255.0, alpha: 1.0)
    public var tintColor: NSColor = NSColor.gray
    public var cornerRadius: CGFloat = 15
    public private(set) var btnClear: NSButton = NSButton.init()

    private var trackingArea: NSTrackingArea?
    private var isEditing = false
    private var isHovered = false
    private var imageCache: NSImage?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initializeSCKeyComboView()
    }

    public init() {
        super.init(frame: NSRect.zero)
        initializeSCKeyComboView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.drawBackground(dirtyRect)
        self.drawKeyCombo(dirtyRect)
        self.drawClearButton(dirtyRect)
    }

    public override func updateTrackingAreas() {
        if nil != trackingArea {
            self.removeTrackingArea(trackingArea!)
        }

        let opts: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .mouseMoved, .activeWhenFirstResponder]
        trackingArea = NSTrackingArea.init(rect: bounds, options: opts, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }

    public override func mouseEntered(with event: NSEvent) {
        if nil == hotKey?.keyCombo {
            isEditing = true
        }
        isHovered = true
        btnClear.animator().isHidden = false
        self.needsDisplay = true
        self.window?.makeFirstResponder(self)
    }

    public override func mouseExited(with event: NSEvent) {
        isEditing = false
        isHovered = false
        btnClear.animator().isHidden = true
        self.needsDisplay = true
        self.window?.makeFirstResponder(nil)
    }

    public override func keyDown(with event: NSEvent) {
        if isEditing {
            var modifiers: Int = 0
            if event.modifierFlags.contains(.command) {
                modifiers += cmdKey
            }
            if event.modifierFlags.contains(.option) {
                modifiers += optionKey
            }
            if event.modifierFlags.contains(.control) {
                modifiers += controlKey
            }
            if event.modifierFlags.contains(.shift) {
                modifiers += shiftKey
            }
            if let combo = hotKey?.keyCombo, event.keyCode == combo.keyCode, modifiers == combo.keyModifiers  {
                return
            }

            delegate?.keyComboWillChange(keyComboView: self)
            if nil == hotKey?.keyCombo {
                hotKey?.keyCombo = SCKeyCombo(keyCode: Int(event.keyCode), keyModifiers: modifiers)
            } else {
                hotKey!.keyCombo!.keyCode = UInt32(event.keyCode)
                hotKey!.keyCombo!.keyModifiers = UInt32(modifiers)
            }
            delegate?.keyComboDidChange(keyComboView: self)
            needsDisplay = true
        }
    }
}

extension SCKeyComboView {
    func initializeSCKeyComboView() {
        btnClear.bezelStyle = .regularSquare
        btnClear.setButtonType(.momentaryChange)
        btnClear.isBordered = false
        btnClear.isHidden = true
        btnClear.title = ""
        btnClear.target = self
        btnClear.action = #selector(clearButton_click(sender:))
        self.addSubview(btnClear)
    }

    func drawBackground(_ dirtyRect: NSRect) {
        if isHovered {
            hoveredBackgroundColor.setFill()
            hoveredBorderColor.setStroke()
        } else {
            backgroundColor.setFill()
            borderColor.setStroke()
        }
        NSBezierPath(roundedRect: dirtyRect, xRadius: cornerRadius, yRadius: cornerRadius).fill()

        let borderWidth: CGFloat = 2.0
        let rct = NSRect(x: borderWidth / 2, y: borderWidth / 2, width: dirtyRect.width - borderWidth, height: dirtyRect.height - borderWidth)
        let path = NSBezierPath(roundedRect: rct, xRadius: cornerRadius, yRadius: cornerRadius)
        path.lineWidth = borderWidth
        path.stroke()
    }

    func drawKeyCombo(_ dirtyRect: NSRect) {
        guard let combo = hotKey?.keyCombo, let code = SCKeyCombo.keyCode2String(keyCode: combo.keyCode, keyModifiers: 0) else {
            return
        }
        let attributedModifier = NSMutableAttributedString(string: "")
        attributedModifier.append(NSAttributedString(string: "⇧", attributes: attribuetes((combo.keyModifiers & UInt32(shiftKey)) != 0)))
        attributedModifier.append(NSAttributedString(string: "⌃", attributes: attribuetes((combo.keyModifiers & UInt32(controlKey)) != 0)))
        attributedModifier.append(NSAttributedString(string: "⌥", attributes: attribuetes((combo.keyModifiers & UInt32(optionKey)) != 0)))
        attributedModifier.append(NSAttributedString(string: "⌘", attributes: attribuetes((combo.keyModifiers & UInt32(cmdKey)) != 0)))

        attributedModifier.append(NSAttributedString(string: "  \(code)", attributes: attribuetes(true)))

        let sizeModifier = attributedModifier.size()
        var rect = bounds
        rect.origin.x = (rect.width - sizeModifier.width) / 2
        rect.origin.y = (sizeModifier.height - rect.height) / 2
        attributedModifier.draw(in: rect)
    }

    func drawClearButton(_ dirtyRect: NSRect) {
        let rect = self.bounds
        let offsetX = rect.width - 16 - cornerRadius * 0.8
        let offsetY = (rect.height - 16) / 2
        btnClear.frame = NSRect.init(x: offsetX, y: offsetY, width: 16, height: 16)
        btnClear.image = clearButtonImage()
    }

    func clearButtonImage() -> NSImage? {
        if nil != imageCache {
            return imageCache
        }
        imageCache = NSImage(size: NSMakeSize(16, 16))
        imageCache?.lockFocus()

        let ovalPath = NSBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 16, height: 16))
        NSColor(calibratedRed: 0.529, green: 0.529, blue: 0.529, alpha: 1).setFill()
        ovalPath.fill()

        NSColor(calibratedRed: 0.871, green: 0.871, blue: 0.871, alpha: 1).setStroke()
        let pathPath = NSBezierPath()
        pathPath.move(to: CGPoint(x: 5, y: 11))
        pathPath.curve(to: CGPoint(x: 11, y: 5), controlPoint1: CGPoint(x: 7, y: 9), controlPoint2: CGPoint(x: 9, y: 7))
        pathPath.lineWidth = 2.0
        pathPath.stroke()
        let path2Path = NSBezierPath()
        path2Path.move(to: CGPoint(x: 11, y: 11))
        path2Path.curve(to: CGPoint(x: 5, y: 5), controlPoint1: CGPoint(x: 9, y: 9), controlPoint2: CGPoint(x: 7, y: 7))
        path2Path.lineWidth = 2.0
        path2Path.stroke()

        imageCache?.unlockFocus()
        return imageCache
    }

    func attribuetes(_ bFlag: Bool) -> [NSAttributedString.Key : Any]? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.baseWritingDirection = .leftToRight
        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[.paragraphStyle] = paragraphStyle
        if bFlag {
            attributes[.foregroundColor] = onTintColor
        } else {
            attributes[.foregroundColor] = tintColor
        }
        attributes[.font] = NSFont(name: "Helvetica", size: bounds.height / 1.7)
        return attributes
    }
}

extension SCKeyComboView {
    @IBAction func clearButton_click(sender: Any?) {
        delegate?.keyComboWillChange(keyComboView: self)
        hotKey?.keyCombo = nil
        isEditing = true
        self.needsDisplay = true
        delegate?.keyComboDidChange(keyComboView: self)
    }
}

extension SCKeyComboView {
    public static func standardKeyComboView() -> SCKeyComboView {
        return SCKeyComboView.init(frame: NSRect.init(x: 0, y: 0, width: 150, height: 30))
    }
}
