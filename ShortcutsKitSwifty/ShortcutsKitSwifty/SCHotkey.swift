//
//  SCHotkey.swift
//  ShortcutsKitSwifty
//
//  Created by Jovi on 12/7/19.
//  Copyright © 2019 Jovi. All rights reserved.
//

import Cocoa
import Carbon

public typealias HotkeyHandler = ((SCHotkey) -> Void)

public class SCHotkey: NSObject {
    public private(set) var identifier: String!
    public private(set) var keyCombo: SCKeyCombo!
    public var target: NSObject?
    public var selector: Selector?
    public var hotkeyHandler: HotkeyHandler?
    public var hotkeyID: UInt = UInt.max
    public var hotkeyRef: EventHotKeyRef?

    public init(keyCombo: SCKeyCombo, identifier: String, target: NSObject, selector: Selector) {
        super.init()
        self.keyCombo = keyCombo
        self.identifier = identifier
        self.target = target
        self.selector = selector
    }

    public init(keyCombo: SCKeyCombo, identifier: String, handler: @escaping HotkeyHandler) {
        self.keyCombo = keyCombo
        self.identifier = identifier
        self.hotkeyHandler = handler
    }

    public func invoke() {
        if nil == hotkeyHandler {
            if target!.responds(to: selector) {
                target?.perform(selector, with: self)
            }
        } else {
            hotkeyHandler?(self)
        }
    }

    @discardableResult public func register() -> Bool {
        return SCHotkeyManager.shared.register(hotkey: self)
    }

    public func unregister() {
        return SCHotkeyManager.shared.unregister(hotkey: self)
    }

    public func updateKeyCombo(newKeyCombo: SCKeyCombo) -> Bool {
        var rslt = true
        if SCHotkeyManager.shared.isRegistered(hotkey: self) {
            SCHotkeyManager.shared.unregister(hotkey: self)
            let tmp = self.keyCombo
            self.keyCombo = newKeyCombo
            if !SCHotkeyManager.shared.register(hotkey: self) {
                rslt = false
                self.keyCombo = tmp
                SCHotkeyManager.shared.register(hotkey: self)
                return rslt
            }
        }
        self.setValue(newKeyCombo, forKey: "keyCombo")
        return rslt
    }

    public override func isEqual(to object: Any?) -> Bool {
        var rslt = false
        if let obj = object as? SCHotkey {
            if obj.keyCombo == self.keyCombo && obj.identifier == self.identifier {
                rslt = true
            }
        }
        return rslt
    }
}
