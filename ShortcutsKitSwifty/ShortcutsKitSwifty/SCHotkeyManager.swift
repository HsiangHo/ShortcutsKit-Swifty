//
//  SCHotkeyManager.swift
//  ShortcutsKitSwifty
//
//  Created by Jovi on 12/8/19.
//  Copyright © 2019 Jovi. All rights reserved.
//

import Cocoa
import Carbon

public class SCHotkeyManager: NSObject {
    public static var shared: SCHotkeyManager = SCHotkeyManager.init()
    private var nIndex: UInt = 0
    private var hotkeyIdentifierMap: [String: SCHotkey] = [:]
    fileprivate var hotkeyIndexMap: [String: SCHotkey] = [:]

    public override init() {
        super.init()
        let eventType = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))]
        InstallEventHandler(GetApplicationEventTarget(), hotKeyEventHandler, 1, eventType, nil, nil)
    }

    @discardableResult public func register(hotkey: SCHotkey) -> Bool {
        var rslt = false
        guard let keyCombo = hotkey.keyCombo else {
            return rslt
        }
        
        var hotKeyRef: EventHotKeyRef? = nil
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = UTGetOSTypeFromString("ShortcutsKit" as CFString)
        hotKeyID.id = UInt32(nIndex)
        let error = RegisterEventHotKey(keyCombo.keyCode, keyCombo.keyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if 0 != error || nil == hotKeyRef {
            return rslt
        }

        hotkey.hotkeyID = nIndex
        nIndex += 1
        hotkey.hotkeyRef = hotKeyRef
        hotkeyIdentifierMap[hotkey.identifier] = hotkey
        hotkeyIndexMap[String(format: "%lu", hotkey.hotkeyID)] = hotkey
        rslt = true
        return rslt
    }

    public func isRegistered(hotkey: SCHotkey) -> Bool {
        return nil != hotkeyIdentifierMap[hotkey.identifier]
    }

    public func unregister(hotkey: SCHotkey) {
        self.unregister(identifier: hotkey.identifier)
    }

    public func unregister(identifier: String) {
        let hotkey = hotkeyIdentifierMap[identifier]
        if nil == hotkey || nil == hotkey?.hotkeyRef {
            return
        }
        UnregisterEventHotKey(hotkey!.hotkeyRef)
        hotkeyIdentifierMap[hotkey!.identifier] = nil
        hotkeyIndexMap[String(format: "%lu", hotkey!.hotkeyID)] = nil
    }

    public func unregisterAllHotkeys() {
        for hotkey in hotkeyIdentifierMap {
            UnregisterEventHotKey(hotkey.value.hotkeyRef!)
        }
        hotkeyIdentifierMap.removeAll()
        hotkeyIndexMap.removeAll()
    }
}

private func hotKeyEventHandler(eventHandlerCall: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event = event else {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID()
    let error = GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    if error != noErr {
        return error
    }

    let hotkey = SCHotkeyManager.shared.hotkeyIndexMap[String(format: "%lu", UInt(hotKeyID.id))]
    hotkey?.invoke()

    return 0
}
