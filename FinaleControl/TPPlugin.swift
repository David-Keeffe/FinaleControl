//
//  TPPlugin.swift
//  TestPlugin
//
//  Created by David Keeffe on 14/08/2020.
//  Copyright © 2020 Music3149. All rights reserved.
//

import Foundation

/**
 This encapsulates the startup and teardown of a Touch Portal plugin.
 
 It uses the local class TCPClient to manage the connection and conversation
 */

class TPPlugin {
    var tpclient: TCPClient?
    typealias Callback = (_ code: [TPPlugin.TPRequestData]) -> Bool
    var keymap: [String: Callback] = [:]
    let thislog: Logger = applog.getsub(location: "tppplugin")
    let defaults = UserDefaults.standard
    var tplocation: String
    var pluginlocation: String
    var tpaddress: String
    var tpport: UInt16
    var tpplugid: String
    var owner: AppDelegate?
    var connected = false
    
    /**
            Set of Codable types that represent the dialog between Touch Portal and this plugin
            Not all types are represented yet.
     */

    struct TPPair: Codable {
        var type = "pair"
        var id: String
    }

    struct TPClose: Codable {
        var type = "close"
        var pluginId: String
    }

    struct TPPairAck: Codable {
        var tpVersionString: String
        var pluginVersion: Int
        var tpVersionCode: Int
        var sdkVersion: Int
        var type: String
        var status: String
    }

    struct TPRequestData: Codable {
        var id: String
        var value: String
    }

    struct TPRequest: Codable {
        var type: String
        var pluginId: String
        var actionId: String
        var data: [TPRequestData]
    }
    
    /**
            initialises the instance with the address and port, and optionally the delegate
     
            - Parameter address: string with DNS name or dotted-quad IP address
            - Parameter port: IPV4 port number
            - Parameter owner: optional AppDelegate, currently not used
     */

    init(address: String, port: UInt16, owner: AppDelegate?) {
        if let tppresent = defaults.string(forKey: "FCTPLocation") {
            self.tplocation = tppresent
        } else {
            self.tplocation = NSString.path(withComponents: [NSHomeDirectory(), "Documents", "TouchPortal"])
        }
        self.pluginlocation = NSString.path(withComponents: [self.tplocation, "plugins", "JSPlugin"])
        self.tpaddress = address
        self.tpport = port
        self.tpplugid = ""

        if FileManager.default.fileExists(atPath: NSString.path(withComponents: [self.pluginlocation, "entry.tp"])) {
            self.tpclient = TCPClient(host: address, port: port)
        } else {
            self.thislog.info("INIT: No Touch Portal plugin descriptor found in \(self.pluginlocation)")
        }
    }

    func reinit() {
        if FileManager.default.fileExists(atPath: NSString.path(withComponents: [self.pluginlocation, "entry.tp"])) {
            self.tpclient = TCPClient(host: self.tpaddress, port: self.tpport)
            self.start(plugid: self.tpplugid)
        } else {
            self.thislog.info("REINIT: No Touch Portal plugin descriptor found in \(self.pluginlocation)")
        }
    }

    func addhandler(key: String, handler: @escaping Callback) {
        self.thislog.debug("ADD HANDLER: \(key) with \(String(describing: handler))")
        self.keymap[key] = handler
    }
    
    /*
     install this app as a Touch Portal plugin
     */

    func install() {
        if let resPath = Bundle.main.resourcePath {
            let desc = "/entry.tp"
            let icon = "/fc-icon-wb-24.png"
            let applocation = Bundle.main.bundlePath
            let tpdescriptor = resPath +  desc
            let tpicon = resPath + icon
            do {
                try FileManager.default.createDirectory(atPath: self.pluginlocation, withIntermediateDirectories: true)
                if (FileManager.default.fileExists(atPath: self.pluginlocation + desc)) {
                    try FileManager.default.removeItem(atPath: self.pluginlocation + desc)
                }
                // fill in the app location for TP to be able to start it
                let descdata = try String(contentsOfFile: tpdescriptor)
                let targetdesc = descdata.replacingOccurrences(of: "{{applocation}}", with: applocation)
                try targetdesc.write(toFile: self.pluginlocation + desc, atomically: false, encoding: .utf8)
                
                //try FileManager.default.copyItem(atPath: tpdescriptor, toPath: self.pluginlocation + desc)
                if (FileManager.default.fileExists(atPath: self.pluginlocation + icon)) {
                    try FileManager.default.removeItem(atPath: self.pluginlocation + icon)
                }
                try FileManager.default.copyItem(atPath: tpicon, toPath: self.pluginlocation + icon)

            } catch {
                self.thislog.info("Create plugin folder or copy failed: \(error)")
            }
        }
    }
    
    /*
     set up the plugin according to current settings and the connect it to Touch Portal
     */

    func start(plugid: String) {
        self.tpplugid = plugid
        if self.connected {
            self.thislog.info("Starting already running TP client")
            return
        }
        self.tpclient?.receiver = {
            data in
            if let stuff = String(bytes: data, encoding: .utf8) {
                // self.thislog.debug("REPLY: \(stuff)")
                // check reply, then dispatch listener on socket
                do {
                    let rdata = try JSONDecoder().decode(TPPairAck.self, from: stuff.data(using: .utf8)!)
                    self.thislog.debug("PAIR REPLY DATA: \(rdata)")
                } catch let Swift.DecodingError.keyNotFound(cause) {
                    do {
                        let rdata = try JSONDecoder().decode(TPRequest.self, from: stuff.data(using: .utf8)!)
                        self.thislog.debug("REQUEST DATA: \(rdata)")
                        if rdata.type == "action" {
                            if let dh = self.keymap[rdata.actionId] {
                                self.thislog.debug("CALL HANDLER FOR \(rdata.actionId)")
                                _ = dh(rdata.data)
                            }
                        }
                    } catch let Swift.DecodingError.keyNotFound(cause) {
                        do {
                            let rdata = try JSONDecoder().decode(TPClose.self, from: stuff.data(using: .utf8)!)
                            self.thislog.debug("CLOSE DATA: \(rdata)")
                            if rdata.type == "close" {
                                if let dh = self.keymap["close"] {
                                    self.thislog.debug("CALL HANDLER FOR close")
                                    _ = dh([])
                                }
                            }
                        } catch {
                            self.thislog.debug("UNKNOWN REQUEST \(cause)")
                        }
                    } catch {
                        self.thislog.error("EEEE \(error)")
                    }
                } catch {
                
                    self.thislog.error("RRRR \(error)")
                }
            }
            return
        }
        // set up the initial connection handler
        self.tpclient?.onReady = {
            // Connection successful 🎉
            self.connected = true
            self.thislog.debug("TP Connection OK")
            let pairer = TPPair(id: plugid)
            do {
                let pj1 = try JSONEncoder().encode(pairer)
                if let pj2 = String(data: pj1, encoding: .utf8) {
                    self.tpclient!.send(data: (pj2 + "\n").data(using: .utf8)!)
                } else {
                    self.thislog.error("encoding failure")
                }
            } catch {
                self.thislog.error("Pairing Failure!!!! \(error)")
            }
        }
        // set up the shutdown handler
        self.tpclient?.ender = {
            error in
            if let err = error {
                AppDelegate.alert("Touch Portal connection failed: \(err)")
            } else {
                AppDelegate.alert("Touch Portal connection lost")
            }
            self.connected = false
        }
        // off we go!
        self.tpclient?.start()
        
    }

}
