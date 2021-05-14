//
//  AppDelegate.swift
//  ShortcutsKitSwiftyDemo
//
//  Created by Jovi on 12/8/19.
//  Copyright © 2019 Jovi. All rights reserved.
//

import Cocoa
import Carbon
import ShortcutsKitSwifty

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!

    var keyComboView = SCKeyComboView.standardKeyComboView()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let keyCombo = SCKeyCombo.init(keyCode: kVK_Space, keyModifiers: shiftKey + optionKey + controlKey)
        print(keyCombo.stringForKeyCombo)

        let data = NSKeyedArchiver.archivedData(withRootObject: keyCombo)
        UserDefaults.standard.setValue(data, forKey: "keyCombo")

        if let dataFromUserDefaults = UserDefaults.standard.data(forKey: "keyCombo"), let keyCombo2 = NSKeyedUnarchiver.unarchiveObject(with: dataFromUserDefaults) as? SCKeyCombo {
            print(keyCombo2.stringForKeyCombo)
        }

        keyComboView.onTintColor = NSColor.red
        keyComboView.delegate = self

        self.window.contentView?.addSubview(keyComboView)

        let shortcut = SCHotkey.init(keyCombo: keyCombo, identifier: "shortcut") { (_) in
            print("shortcut has been called")
        }
        shortcut.register()
        
        keyComboView.hotKey = shortcut

        let keyCombo3 = SCKeyCombo.init(keyCode: kVK_ANSI_B, keyModifiers: optionKey + controlKey)
        let shortcut2 = SCHotkey.init(keyCombo: keyCombo3, identifier: "shortcut2", target: self, selector: #selector(shortcut2Callback(hotkey:)))
        shortcut2.register()

//        shortcut.invoke()
//        shortcut.unregister()
//
//        SCHotkeyManager.shared.register(hotkey: shortcut)
//        SCHotkeyManager.shared.unregister(identifier: "shortcut")
//        SCHotkeyManager.shared.unregister(hotkey: shortcut2)
//        SCHotkeyManager.shared.unregisterAllHotkeys()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func shortcut2Callback(hotkey: SCHotkey) {
        print("shortcut2 has been called")
    }

}

extension AppDelegate: SCKeyComboViewDelegate {
    func keyComboWillChange(keyComboView: SCKeyComboView) {
        keyComboView.hotKey?.unregister()
    }

    func keyComboDidChange(keyComboView: SCKeyComboView) {
        keyComboView.hotKey?.register()
    }
}

