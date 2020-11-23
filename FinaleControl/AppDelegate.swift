//
//  AppDelegate.swift
//  FinaleControl
//
//  Created by David Keeffe on 07/08/2020.
//  Copyright © 2020 Music3149. All rights reserved.
//

import AXSwift
import Cocoa
import Network
import PromiseKit
import Swindler

func dispatchAfter(delay: TimeInterval, block: DispatchWorkItem) {
    let time = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: time, execute: block)
}

// https://eastmanreference.com/complete-list-of-applescript-key-codes
// OBS! The codes are not quite sequential.

let keymap: [String: UInt16] = [
    "0": 0x1d,
    "1": 0x12,
    "2": 0x13,
    "3": 0x14,
    "4": 0x15,
    "5": 0x17,
    "6": 0x16,
    "7": 0x1a,
    "8": 0x1c,
    "9": 0x19
]

class AppDelegate: NSObject, NSApplicationDelegate {
    var swindler: Swindler.State!
    var finale: AXSwift.Application?
    var httpserver: RestHandler!
    var keyseq: String?
    var triggered: Bool = false
    var controller: ViewController?
    var newWindow: NSWindow?
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let defaults = UserDefaults.standard
    let popover = NSPopover()
    var plugin: TPPlugin!
    
    var clickable: [String: UIElement] = [:]
    
    // update profile to context path (array) and then click item (string)
    func clickItem(app: UIElement, context: [String], name: String, code: String) {
        applog.debug("CLICKITEM: \(context) -> \(name)")
        
        let finaleactive = try? (finale?.attribute(.frontmost)! as Bool?)
        
        guard finaleactive != nil, finaleactive == true else {
            AppDelegate.alert("Finale must be running and at the front.")
            return
        }
        
        
        let fullname = context.joined(separator: ".") + "." + name
        
        if let xelement = clickable[fullname] {
            keyseq = code
            applog.debug("cached menu click: \(fullname)")
            do {
                try xelement.performAction(.pick)
                wait()
                usleep(50000)
                return
            } catch {
                applog.error("Menu click failed: \(error)")
                clickable[fullname] = nil
            }
            
        }
        
        let menubar: UIElement = try! app.attribute(.menuBar)!
        let mitems: [AXUIElement] = try! menubar.attribute(.children)!
       
        // NSLog("Menu XXX \(mitems)")
       
        var uilist = mitems
        // NSLog("ATTRS \(uilist)")
        
        /*
         set current target to first item, current source to main menu bar
         move current to next item, current source to found menu
         */
                
        for target in context {
            var found = false
            applog.debug("MENU CHECK \(target)")
            for uie_x in uilist {
                let uie = UIElement(uie_x)
                let vxvx: NSString = try! uie.attribute(.title)!
                        
                if vxvx.isEqual(to: target) {
                    applog.debug("UI Element Match: \(vxvx) = \(target)")
                    let muilist_x: [AXUIElement] = try! uie.attribute(.children)!
                    let themenu: UIElement = UIElement(muilist_x.first!)
                                
                    applog.debug("MENU \(target) MEMBERS: \(themenu)")
                            
                    // get member of menu members
                    uilist = try! themenu.attribute(.children)!
                    found = true
                    break
                }
            }
            if !found {
                applog.info("MENU - \(target) not found")
                return
            }
        }
        applog.debug("MENU: context \(context) found: seek \(name) in \(uilist)")
        
        /*
         if we get here, we've found the context: all we need to do is click
         */
        for lua_x in uilist {
            let lua = UIElement(lua_x)
            let luas: NSString = try! lua.attribute(.title)!
            applog.debug("MENU: target element title \(luas) in \(lua)")
            if luas.isEqual(name) {
                applog.debug("MENU ITEM ATTR: \(try! lua.attributes())")
                keyseq = code
                clickable[fullname] = lua
                try! lua.performAction(.pick)
                wait()
                usleep(50000)
            }
        }
    }
    
    func doBox(app: AXSwift.Application, code: String) {
        if !triggered {
            return
        }
        let luawx: UIElement = try! app.attribute(.focusedWindow)!
        let actions = try! luawx.actionsAsStrings()
        // applog.debug("ACTIONS \(actions)")
        // applog.debug("WIN XX ATTR: \(try! luawx.attributes())")
        // try! luawx.performAction(.raise)
        try! luawx.setAttribute(.focused, value: true)
        let muw_members: [AXUIElement] = try! luawx.attribute(.children)!
        // applog.debug("WIN XX MEMBERS: \(muw_members)")
        var okbutton: UIElement = luawx
        var cancelbutton: UIElement = luawx
        for mem_x in muw_members {
            // applog.debug("MEMBER \(mem_x)")
            let mem: UIElement? = UIElement(mem_x)
            
            if let xmem = mem {
                do {
                    if try xmem.attributeIsSupported(.title) {
                        let wtitle: String? = try xmem.attribute(.title)
                        if let xtitle = wtitle {
                            if xtitle.isEqual("OK") {
                                applog.debug("FOUND OK")
                                okbutton = xmem
                            } else if xtitle.isEqual("Cancel") {
                                applog.debug("FOUND Cancel")
                                cancelbutton = xmem
                            }
                        }
                    }
                } catch {}
            }
        }
        // wait()
        // usleep(200000)
        if code.count == 4 {
            for cc in code {
                let kc: UInt16 = keymap[String(cc)]!
                let keydownevent = CGEvent(keyboardEventSource: nil, virtualKey: kc, keyDown: true)!
                let keyupevent = CGEvent(keyboardEventSource: nil, virtualKey: kc, keyDown: false)!
                keydownevent.post(tap: .cghidEventTap)
                keyupevent.post(tap: .cghidEventTap)
            }
                
            // keyRETupevent.post(tap:.cghidEventTap)
            // keyRETdownevent.post(tap:.cghidEventTap)
            // try! luawx.performAction(.cancel)
            applog.debug("DISPATCH OK")
            usleep(100000)
            do {
                try okbutton.performAction(.press)
            } catch {
                let x = 1
            }
            triggered = false
            
            /*
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            applog.debug("CLICK OK")
                            try! okbutton.performAction(.press)
                            self.triggered = false
                        }
             */
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                try! cancelbutton.performAction(.press)
                self.triggered = false
            }
        }
        
        // break
    }
                                   
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard AXSwift.checkIsProcessTrusted(prompt: true) else {
            NSLog("Not trusted as an AX process; please authorize and re-launch")
            NSApp.terminate(self)
            return
        }
        
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("icon_32x32"))
            button.image?.size = NSMakeSize(18.0,18.0)
            // button.action = #selector(applog.debugQuote(_:))
        }
        
        applog.info("FinaleControl: resources in \(String(describing: Bundle.main.resourcePath))")
        
        var theport: UInt16 = UInt16(defaults.integer(forKey: "FCIPport"))
        if theport == 0 {
            theport = 8765
        }

        httpserver = RestHandler(port: theport)
        plugin = TPPlugin(address: "127.0.0.1", port: 12136, owner: self)
        
        if let xplug = plugin {
            xplug.addhandler(key: "com.music3149.jsplugin.cat_action1.luacode") {
                code in
                applog.debug("LUA HANDLER: \(code)")
                if let xapp = self.finale {
                    self.triggered = true
                    self.clickItem(app: xapp, context: ["Plug-ins", "JW Lua"], name: "JetStream Finale Controller", code: code[0].value)
                    return true
                } else {
                    return false
                }
            }
            xplug.addhandler(key: "com.music3149.jsplugin.cat_action3.focus") {
                _ in
                applog.debug("FOCUS HANDLER")
                if let xapp = self.finale {
                    do {
                        try xapp.setAttribute(.frontmost, value: true)
                    } catch {
                        applog.error("Finale went away")
                        AppDelegate.alert("Finale went away")
                    }
                    return true
                } else {
                    return false
                }
            }
            xplug.addhandler(key: "com.music3149.jsplugin.cat_action2.menu") {
                code in
                applog.debug("MENU HANDLER: \(code)")
                // work out the code values
                var context: [String] = []
                var target: String = ""
                for cc in code {
                    if cc.id == "com.music3149.jsplugin.cat_action2.context" {
                        context = cc.value.components(separatedBy: "|")
                        applog.debug("MENU CONTEXT: \(context)")
                    } else if cc.id == "com.music3149.jsplugin.cat_action2.target" {
                        target = cc.value
                        applog.debug("MENU TARGET: \(target)")
                    }
                }
                
                if let xapp = self.finale {
                    // self.triggered = true
                    self.clickItem(app: xapp, context: context, name: target, code: "")
                    return true
                } else {
                    return false
                }
            }
            xplug.start(plugid: "com.music3149.jsplugin")
        }
        
        if let xhttp = httpserver {
            xhttp.addhandler(key: "/fred") {
                code in
                if let xapp = self.finale {
                    self.triggered = true
                    self.clickItem(app: xapp, context: ["Plug-ins", "JW Lua"], name: "JetStream Finale Controller", code: code)
                    return true
                } else {
                    return false
                }
            }
            xhttp.addhandler(key: "/dolua") {
                code in
                if let xapp = self.finale {
                    self.triggered = true
                    self.clickItem(app: xapp, context: ["Plug-ins", "JW Lua"], name: "JetStream Finale Controller", code: code)
                    return true
                } else {
                    return false
                }
            }
            xhttp.addhandler(key: "/domenu") {
                code in
                if let xapp = self.finale {
                    self.triggered = true
                    let items = code.components(separatedBy: "|")
                    applog.debug("MENU CALL: \(code) -> \(items)")
                    self.clickItem(app: xapp, context: items.dropLast(), name: items.last!, code: "")
                    return true
                } else {
                    return false
                }
            }
            xhttp.addhandler(key: "/focus") {
                _ in
                try! self.finale?.setAttribute(.frontmost, value: true)
                return true
            }
            
            xhttp.addhandler(key: "/tpconnect") {
                _ in
                self.plugin?.reinit()
                return true
            }
        
            if let myindex = defaults.string(forKey: "FCIndexPage") {
                xhttp.addRootIndex(path: myindex)
            }
            if let myassets = defaults.string(forKey: "FCAssetDir") {
                xhttp.addAssetPath(path: myassets)
            }
            xhttp.start()
        }
        
        Swindler.initialize().done { state in
            self.swindler = state
            self.setupEventHandlers()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // your function here
                // check for Finale
                self.finale = Application.allForBundleID("com.makemusic.Finale26").first
                applog.debug("APP ATTRS: \(try? self.finale?.attributes())")
                try? self.finale?.setAttribute(.frontmost, value: true)
                // self.clickItem(app: app, name: "JetStream Finale Controller")
            }
        }.catch { error in
            applog.debug("Fatal error: failed to initialize Swindler: \(error)")
            NSApp.terminate(self)
        }
        // let storyboard:NSStoryboard? = NSStoryboard.main // NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        // self.controller = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Main")) as! ViewController
        constructMenu()
        
        popover.contentViewController = ViewController.freshController()
        
        defaults.set(true, forKey: "FCHasRun")
    }

    private func setupEventHandlers() {
        applog.debug("screens: \(swindler.screens)")
        
        swindler.on { (event: WindowCreatedEvent) in
            let window = event.window
            applog.debug("new window: \(window.title.value)")
        }
        swindler.on { (event: WindowFrameChangedEvent) in
            applog.debug("Frame changed from \(event.oldValue) to \(event.newValue)," +
                " external: \(event.external)")
        }
        swindler.on { (event: WindowDestroyedEvent) in
            applog.debug("window destroyed: \(event.window.title.value)")
        }
        swindler.on { (event: ApplicationMainWindowChangedEvent) in
            applog.debug("new main window: \(String(describing: event.newValue?.title.value))." +
                " [old: \(String(describing: event.oldValue?.title.value))]")
            self.frontmostWindowChanged()
        }
        swindler.on { (event: FrontmostApplicationChangedEvent) in
            let bundle = event.newValue?.bundleIdentifier
            applog.debug("new frontmost app: \(event.newValue?.bundleIdentifier ?? "unknown")." +
                " [old: \(event.oldValue?.bundleIdentifier ?? "unknown")]")
            
            if let xbundle = bundle {
                if xbundle.isEqual("com.makemusic.Finale26") {
                    // self.clickItem(app: self.finale, name: "JetStream Finale Controller")
                    self.finale = Application.allForBundleID("com.makemusic.Finale26").first
                    do {
                        applog.debug("NEW APP ATTRS: \(try self.finale?.attributes())")
                        try self.finale?.setAttribute(.frontmost, value: true)
                    } catch {
                        applog.error("Set Finale frontmost fail: \(error)")
                    }
                }
            }
            
            self.frontmostWindowChanged()
        }
    }

    private func frontmostWindowChanged() {
        let window = swindler.frontmostApplication.value?.mainWindow.value
        let wtitle = window?.title.value
        applog.debug("new frontmost window: \(String(describing: wtitle))")
        if let xwtitle = wtitle, let xapp = finale, let xcode = keyseq {
            if xwtitle.isEqual("JetStream Finale Controller") {
                applog.debug("FINALE: JW BOX!")
                if triggered {
                    doBox(app: xapp, code: xcode)
                    keyseq = nil
                }
            }
        }
    }
    
    static var alerter: NSAlert?
    
    static func alert(_ message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.alerter = NSAlert()
            self.alerter?.messageText = message
            // alert.informativeText = text
            self.alerter?.alertStyle = .warning
            self.alerter?.addButton(withTitle: "OK")
            // alert.addButton(withTitle: "Cancel")
            _ = self.alerter?.runModal()
        }
    }
    
    @objc func showSettings(_ sender: Any?) {
        let quoteText = "Never put off until tomorrow what you can do the day after tomorrow."
        let quoteAuthor = "Mark Twain"
      
        applog.debug("\(quoteText) — \(quoteAuthor)")
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
    @objc func makePlugin(_ sender: Any?) {
        plugin.install()
        AppDelegate.alert("Restart Touch Portal to accept the plugin. Then choose menu item 'Connect to Touch Portal..'")
        return
    }
    
    @objc func startPlugin(_ sender: Any?) {
        plugin.reinit()
    
        return
    }
    
    @objc func showAbout(_ sender: Any?) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        let copyright = CFXMLCreateStringByUnescapingEntities(nil, "&#169;2020 Music3149" as CFString, nil)! as String
        AppDelegate.alert("FinaleControl\nversion \(appVersion) build \(appBuild)\n\(copyright)")
    }
    
    func constructMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "About FinaleControl", action: #selector(AppDelegate.showAbout(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Add to Touch Portal...", action: #selector(AppDelegate.makePlugin(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Connect to Touch Portal...", action: #selector(AppDelegate.startPlugin(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit FinaleControl", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))

        statusItem.menu = menu
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
