//
//  SCKeyCombo.swift
//  ShortcutsKitSwifty
//
//  Created by Jovi on 12/7/19.
//  Copyright © 2019 Jovi. All rights reserved.
//

import Cocoa
import Carbon

public class SCKeyCombo: NSObject, NSCoding {
    public var keyCode: UInt32
    public var keyModifiers: UInt32
    public var stringForKeyCombo: String {
        var rslt: String = ""
        if let modifiers = SCKeyCombo.keyModifiers2String(keyModifiers: keyModifiers) {
            rslt = rslt.appending(modifiers)
        }
        if let key = SCKeyCombo.keyCode2String(keyCode: keyCode, keyModifiers: 0) {
            rslt = rslt.appending(key)
        }
        return rslt
    }

    public init(keyCode: Int, keyModifiers: Int) {
        self.keyCode = UInt32(keyCode)
        self.keyModifiers = UInt32(keyModifiers)
        super.init()
    }

    public required init?(coder: NSCoder) {
        keyCode = (coder.decodeObject(forKey: "keyCode") as! NSNumber).uint32Value
        keyModifiers = (coder.decodeObject(forKey: "keyModifiers") as! NSNumber).uint32Value
    }

    public func encode(with coder: NSCoder) {
        coder.encode(NSNumber.init(value: keyCode), forKey: "keyCode")
        coder.encode(NSNumber.init(value: keyModifiers), forKey: "keyModifiers")
    }

    public override func isEqual(_ object: Any?) -> Bool {
        var rslt = false
        if let obj = object as? SCKeyCombo {
            rslt = ((obj.keyCode == self.keyCode) && (obj.keyModifiers == self.keyModifiers))
        }
        return rslt
    }
}

extension SCKeyCombo {
    private static func specialkeyCode2String(keyCode: UInt32) -> String? {
        func NSStringFromKeyCode(_ keyCode: UInt32) -> String {
            return NSString.init(format: "%C", keyCode) as String
        }

        func NSNumberFromKeyCode(_ keyCode: Int) -> NSNumber {
            return NSNumber.init(value: keyCode)
        }

        var dictSpecialKeyCode2String: [NSObject: String] = [:]
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F1)] = "F1"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F2)] = "F2"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F3)] = "F3"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F4)] = "F4"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F5)] = "F5"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F6)] = "F6"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F7)] = "F7"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F8)] = "F8"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F9)] = "F9"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F10)] = "F10"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F11)] = "F11"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F12)] = "F12"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F13)] = "F13"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F14)] = "F14"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F15)] = "F15"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F16)] = "F16"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F17)] = "F17"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F18)] = "F18"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F19)] = "F19"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_F20)] = "F20"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_Space)] = "Space"
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_Delete)] = NSStringFromKeyCode(0x232B)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_ForwardDelete)] = NSStringFromKeyCode(0x2326)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_ANSI_Keypad0)] = NSStringFromKeyCode(0x2327)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_LeftArrow)] = NSStringFromKeyCode(0x2190)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_RightArrow)] = NSStringFromKeyCode(0x2192)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_UpArrow)] = NSStringFromKeyCode(0x2191)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_DownArrow)] = NSStringFromKeyCode(0x2193)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_End)] = NSStringFromKeyCode(0x2198)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_Home)] = NSStringFromKeyCode(0x2196)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_Escape)] = NSStringFromKeyCode(0x238B)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_PageDown)] = NSStringFromKeyCode(0x21DF)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_PageUp)] = NSStringFromKeyCode(0x21DE)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_Return)] = NSStringFromKeyCode(0x21A9)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_ANSI_KeypadEnter)] = NSStringFromKeyCode(0x2305)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_Tab)] = NSStringFromKeyCode(0x21E5)
        dictSpecialKeyCode2String[NSNumberFromKeyCode(kVK_Help)] = "?⃝"

        return dictSpecialKeyCode2String[NSNumberFromKeyCode(Int(keyCode))]
    }
}

extension SCKeyCombo {
    public static func keyCode2String(keyCode: UInt32, keyModifiers: UInt32) -> String? {
        var rslt = specialkeyCode2String(keyCode: keyCode)
        if nil != rslt {
            return rslt
        }

        let currentKeyboard =  TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeUnretainedValue()
        let rawLayoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData)

        let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self)
        let layout: UnsafePointer<UCKeyboardLayout> = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var chars: [UniChar] = [0]
        var realLength: Int = 0
        let modifierKeyState: UInt32 = (keyModifiers >> 8) & 0xff

        let result = UCKeyTranslate(layout,
                                    UInt16(keyCode),
                                    UInt16(kUCKeyActionDown),
                                    modifierKeyState,
                                    UInt32(LMGetKbdType()),
                                    OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                    &deadKeyState,
                                    4,
                                    &realLength,
                                    &chars)

        if noErr == result {
            rslt = NSString.init(characters: chars, length: realLength) as String
        }
        return rslt
    }

    public static func keyModifiers2String(keyModifiers: UInt32) -> String? {
        var rslt: String = ""
        let modifiers = Int(keyModifiers)
        if (modifiers & shiftKey) == shiftKey {
            rslt = rslt.appending("⇧")
        }
        if (modifiers & controlKey) == controlKey {
            rslt = rslt.appending("⌃")
        }
        if (modifiers & optionKey) == optionKey {
            rslt = rslt.appending("⌥")
        }
        if (modifiers & cmdKey) == cmdKey {
            rslt = rslt.appending("⌘")
        }
        return rslt == "" ? nil : rslt
    }
}
