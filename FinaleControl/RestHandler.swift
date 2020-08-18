//
//  RestHandler.swift
//  SwindlerExample
//
//  Created by David Keeffe on 06/08/2020.
//  Copyright © 2020 Tyler Mandry. All rights reserved.
//

import Foundation
import Swifter

class RestHandler {
    var server: HttpServer
    var port: UInt16
    typealias Callback = (_ code: String) -> Bool
    let thislog: Logger = applog.getsub(location: "resthandler")
    
    init(port: UInt16) {
        self.server = HttpServer()
        self.server.listenAddressIPv4 = "0.0.0.0"
        self.port = port
        if let resPath = Bundle.main.resourcePath {
            let indexfile = resPath + "/index.html"
            let assetpath = resPath + "/WebAssets"
            self.server["/"] = shareFile(indexfile)
            self.server["/assets/:path"] = shareFilesFromDirectory(assetpath)
        }
    }
    
    func addhandler(key: String, handler: @escaping Callback) {
        self.thislog.debug("ADD HANDLER: \(key) with \(String(describing: handler))")
        self.server[key] = { request in
            self.thislog.debug("GOT \(key) \(request.queryParams)")
            let code: String? = request.queryParams.filter({ $0.0 == "code"}).first?.1
            var xx: Bool = false
            if let xcode = code {
                xx = handler(xcode)
            } else {
                xx = handler("")
            }
            
            return HttpResponse.ok(.text("<h1>\(xx)</h1>"))
        }
    }
    
    func resetRoot() {
        if let resPath = Bundle.main.resourcePath {
            let indexfile = resPath + "/index.html"
            self.server["/"] = shareFile(indexfile)
        }
    }
    
    
    func resetAssets() {
        if let resPath = Bundle.main.resourcePath {
            let assetpath = resPath + "/WebAssets"
            self.server["/assets/:path"] = shareFilesFromDirectory(assetpath)
        }
    }
    
    func addRootIndex(path: String) {
        self.server["/"] = shareFile(path)
    }
    
    func addAssetPath(path: String) {
        self.server["/assets/:path"] = shareFilesFromDirectory(path)
    }
    
    func start() {
        try! self.server.start(self.port)
    }

}
